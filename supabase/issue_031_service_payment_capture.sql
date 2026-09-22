-- ISSUE-031 - Recebimentos seguros dos atendimentos
-- Aplicar depois de issue_029_owner_dashboard_details.sql e
-- issue_030_barber_commission_metrics.sql.
begin;

alter table public.payments
  add column if not exists idempotency_key uuid;

create unique index if not exists idx_payments_idempotency_key
  on public.payments(idempotency_key)
  where idempotency_key is not null;

alter table public.cash_movements
  add column if not exists payment_id uuid
    references public.payments(id) on delete restrict;

create unique index if not exists idx_cash_movements_payment_id
  on public.cash_movements(payment_id)
  where payment_id is not null;

-- Amarra cada pagamento à mesma barbearia do atendimento. NOT VALID permite
-- detectar dados legados durante a validação sem bloquear a criação inicial;
-- VALIDATE falha e reverte a migration se houver inconsistência a corrigir.
create unique index if not exists idx_appointments_id_shop
  on public.appointments(id, barber_shop_id);
create unique index if not exists idx_payments_id_shop
  on public.payments(id, barber_shop_id);

do $$
begin
  if not exists (
    select 1 from pg_catalog.pg_constraint
     where conname = 'payments_appointment_shop_fkey'
       and conrelid = 'public.payments'::regclass
  ) then
    alter table public.payments
      add constraint payments_appointment_shop_fkey
      foreign key (appointment_id, barber_shop_id)
      references public.appointments(id, barber_shop_id)
      on delete cascade
      not valid;
  end if;
  if not exists (
    select 1 from pg_catalog.pg_constraint
     where conname = 'cash_movements_payment_shop_fkey'
       and conrelid = 'public.cash_movements'::regclass
  ) then
    alter table public.cash_movements
      add constraint cash_movements_payment_shop_fkey
      foreign key (payment_id, barber_shop_id)
      references public.payments(id, barber_shop_id)
      not valid;
  end if;
end;
$$;

alter table public.payments
  validate constraint payments_appointment_shop_fkey;
alter table public.cash_movements
  validate constraint cash_movements_payment_shop_fkey;

-- O preço é um snapshot comercial do agendamento e não pode ser alterado por
-- clientes ou membros via PATCH direto. Conclusão/status de atendimento só
-- muda pelo RPC transacional, usando um marcador local à transação.
create or replace function public.guard_appointment_financial_snapshot()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is null then
    return new;
  end if;

  if new.barber_shop_id is distinct from old.barber_shop_id
     or new.client_id is distinct from old.client_id
     or new.barber_id is distinct from old.barber_id
     or new.service_id is distinct from old.service_id
     or new.total_price is distinct from old.total_price then
    raise exception 'Os dados comerciais do agendamento não podem ser alterados diretamente.';
  end if;

  if (new.status is distinct from old.status
      and (new.status = 'completed' or old.status = 'completed'))
     or new.completed_at is distinct from old.completed_at then
    if pg_catalog.current_setting('app.appointment_completion_rpc', true)
       is distinct from 'true' then
      raise exception 'Conclua o atendimento pelo fluxo oficial da Agenda.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_appointment_financial_snapshot
  on public.appointments;
create trigger guard_appointment_financial_snapshot
before update on public.appointments
for each row execute function public.guard_appointment_financial_snapshot();

-- Uma entrada criada pelo RPC é um espelho imutável do pagamento. Mantém a
-- correção (pagamento/loja/atendimento/valor) e exige fluxo futuro de estorno,
-- em vez de permitir edição ou exclusão silenciosa pelo Caixa.
create or replace function public.guard_linked_service_cash_movement()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  linked_payment public.payments%rowtype;
begin
  if tg_op = 'DELETE' then
    if old.payment_id is not null then
      raise exception 'Estorne o recebimento pelo fluxo financeiro; a entrada vinculada não pode ser excluída.';
    end if;
    return old;
  end if;

  if tg_op = 'UPDATE' and old.payment_id is not null then
    raise exception 'A entrada vinculada a um recebimento não pode ser alterada.';
  end if;

  if new.payment_id is not null then
    select * into linked_payment
      from public.payments payment
     where payment.id = new.payment_id
       and payment.barber_shop_id = new.barber_shop_id
       and payment.appointment_id = new.appointment_id
       and payment.status = 'paid'
       and payment.amount = new.amount;
    if not found or new.type <> 'income' then
      raise exception 'A entrada de caixa não corresponde ao recebimento vinculado.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_linked_service_cash_movement
  on public.cash_movements;
create trigger guard_linked_service_cash_movement
before insert or update or delete on public.cash_movements
for each row execute function public.guard_linked_service_cash_movement();

-- Escrita de pagamentos passa pelo RPC abaixo. Clientes ainda podem criar
-- intents PIX pendentes pela policy payments_insert_client_pix existente.
drop policy if exists payments_manage_staff on public.payments;

drop policy if exists payments_read_involved on public.payments;
create policy payments_read_involved on public.payments
for select using (
  public.is_platform_admin()
  or public.is_shop_owner_or_manager(barber_shop_id)
  or public.is_shop_member(barber_shop_id)
  or exists (
    select 1
      from public.appointments appointment
     where appointment.id = public.payments.appointment_id
       and appointment.barber_shop_id = public.payments.barber_shop_id
       and appointment.client_id = auth.uid()
  )
  or exists (
    select 1
      from public.appointments appointment
      join public.barbers barber
        on barber.id = appointment.barber_id
       and barber.barber_shop_id = appointment.barber_shop_id
     where appointment.id = public.payments.appointment_id
       and appointment.barber_shop_id = public.payments.barber_shop_id
       and barber.user_id = auth.uid()
       and barber.is_active = true
       and public.is_shop_member(
         appointment.barber_shop_id,
         array['barber']::public.shop_member_role[]
       )
  )
);

create or replace function public.complete_appointment_with_payment(
  p_appointment_id uuid,
  p_payment_method public.payment_method default null,
  p_payment_amount numeric default null,
  p_idempotency_key uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  appointment_row public.appointments%rowtype;
  existing_payment public.payments%rowtype;
  payment_id uuid;
  paid_before numeric(10,2);
  paid_after numeric(10,2);
  balance_before numeric(10,2);
  shop_timezone text;
begin
  if auth.uid() is null then
    raise exception 'É necessário entrar na conta para registrar o atendimento.';
  end if;

  select *
    into appointment_row
    from public.appointments appointment
   where appointment.id = p_appointment_id
   for update;
  if not found then
    raise exception 'Agendamento não encontrado.';
  end if;

  if not (
    public.is_platform_admin()
    or public.is_shop_owner_or_manager(appointment_row.barber_shop_id)
    or (
      public.is_shop_member(
        appointment_row.barber_shop_id,
        array['barber']::public.shop_member_role[]
      )
      and exists (
      select 1
        from public.barbers barber
       where barber.id = appointment_row.barber_id
         and barber.barber_shop_id = appointment_row.barber_shop_id
         and barber.user_id = auth.uid()
         and barber.is_active = true
      )
    )
  ) then
    raise exception 'Você não tem permissão para concluir este atendimento.';
  end if;

  if appointment_row.status not in ('pending', 'confirmed', 'completed') then
    raise exception 'Este atendimento não pode ser concluído.';
  end if;

  if (p_payment_method is null) <> (p_payment_amount is null) then
    raise exception 'Informe forma e valor do pagamento.';
  end if;
  if p_payment_amount is null and p_idempotency_key is not null then
    raise exception 'Chave de pagamento informada sem um recebimento.';
  end if;
  if p_payment_amount is not null and p_idempotency_key is null then
    raise exception 'Não foi possível identificar esta tentativa de pagamento.';
  end if;
  if p_payment_amount is not null and
     (p_payment_amount <= 0 or p_payment_amount <> round(p_payment_amount, 2)) then
    raise exception 'Informe um valor recebido válido, com até duas casas decimais.';
  end if;

  if appointment_row.status in ('pending', 'confirmed') then
    perform pg_catalog.set_config(
      'app.appointment_completion_rpc', 'true', true
    );
    update public.appointments
       set status = 'completed',
           completed_at = coalesce(completed_at, now())
     where id = appointment_row.id;
    appointment_row.status := 'completed';
  elsif appointment_row.completed_at is null then
    perform pg_catalog.set_config(
      'app.appointment_completion_rpc', 'true', true
    );
    update public.appointments
       set completed_at = now()
     where id = appointment_row.id;
  end if;

  select coalesce(sum(payment.amount), 0)::numeric(10,2)
    into paid_before
    from public.payments payment
   where payment.appointment_id = appointment_row.id
     and payment.barber_shop_id = appointment_row.barber_shop_id
     and payment.status = 'paid';

  if p_idempotency_key is not null then
    select *
      into existing_payment
      from public.payments payment
     where payment.idempotency_key = p_idempotency_key;
    if found then
      if existing_payment.appointment_id <> appointment_row.id
         or existing_payment.method <> p_payment_method
         or existing_payment.amount <> p_payment_amount
         or existing_payment.status <> 'paid' then
        raise exception 'A chave de pagamento já foi usada em outra operação.';
      end if;
      return jsonb_build_object(
        'appointment_id', appointment_row.id,
        'payment_id', existing_payment.id,
        'status', 'completed',
        'paid_amount', paid_before,
        'balance_due', greatest(appointment_row.total_price - paid_before, 0)
      );
    end if;
  end if;

  if p_payment_amount is not null then
    balance_before := greatest(appointment_row.total_price - paid_before, 0);
    if balance_before <= 0 then
      raise exception 'Este atendimento já está totalmente pago.';
    end if;
    if p_payment_amount > balance_before then
      raise exception 'O valor informado supera o saldo devedor do atendimento.';
    end if;

    insert into public.payments (
      barber_shop_id,
      appointment_id,
      method,
      status,
      amount,
      paid_at,
      idempotency_key
    ) values (
      appointment_row.barber_shop_id,
      appointment_row.id,
      p_payment_method,
      'paid',
      p_payment_amount,
      now(),
      p_idempotency_key
    ) returning id into payment_id;

    select coalesce(nullif(shop.timezone, ''), 'America/Sao_Paulo')
      into shop_timezone
      from public.barber_shops shop
     where shop.id = appointment_row.barber_shop_id;

    insert into public.cash_movements (
      barber_shop_id,
      appointment_id,
      payment_id,
      type,
      amount,
      description,
      movement_date,
      created_by
    ) values (
      appointment_row.barber_shop_id,
      appointment_row.id,
      payment_id,
      'income',
      p_payment_amount,
      'Recebimento de atendimento #' || left(appointment_row.id::text, 8),
      (now() at time zone shop_timezone)::date,
      auth.uid()
    );
  end if;

  select coalesce(sum(payment.amount), 0)::numeric(10,2)
    into paid_after
    from public.payments payment
   where payment.appointment_id = appointment_row.id
     and payment.barber_shop_id = appointment_row.barber_shop_id
     and payment.status = 'paid';

  return jsonb_build_object(
    'appointment_id', appointment_row.id,
    'payment_id', payment_id,
    'status', 'completed',
    'paid_amount', paid_after,
    'balance_due', greatest(appointment_row.total_price - paid_after, 0)
  );
end;
$$;

revoke all on function public.complete_appointment_with_payment(
  uuid, public.payment_method, numeric, uuid
) from public, anon;
grant execute on function public.complete_appointment_with_payment(
  uuid, public.payment_method, numeric, uuid
) to authenticated;

-- Compatibilidade com clientes antigos sem manter um caminho de autorização
-- mais amplo: a RPC anterior delega à mesma implementação segura.
create or replace function public.complete_appointment(p_appointment_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.complete_appointment_with_payment(
    p_appointment_id, null, null, null
  );
  return true;
end;
$$;

revoke all on function public.complete_appointment(uuid) from public, anon;
grant execute on function public.complete_appointment(uuid) to authenticated;

create or replace function public.get_owner_dashboard_details_v2(
  p_barber_shop_id uuid,
  p_days integer,
  p_kind text
)
returns table(
  id uuid,
  occurred_at timestamptz,
  customer_name text,
  service_name text,
  barber_name text,
  status text,
  cancellation_reason text,
  total_price numeric,
  paid_amount numeric
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_timezone text;
  v_today date;
  v_from date;
  v_start timestamptz;
  v_end timestamptz;
begin
  if p_days is null or p_days not in (1, 7, 30) then
    raise exception 'Período inválido para os detalhes do painel.';
  end if;
  if p_kind is null or p_kind not in
     ('appointments', 'cancelled', 'completed', 'new_customers') then
    raise exception 'Tipo inválido para os detalhes do painel.';
  end if;
  if not public.is_shop_owner_or_manager(p_barber_shop_id) then
    raise exception 'Acesso negado ao painel desta barbearia.';
  end if;

  select coalesce(shop.timezone, 'America/Sao_Paulo')
    into v_timezone
    from public.barber_shops shop
   where shop.id = p_barber_shop_id;
  if v_timezone is null then
    raise exception 'Barbearia não encontrada.';
  end if;

  v_today := (now() at time zone v_timezone)::date;
  v_from := v_today - (p_days - 1);
  v_start := v_from::timestamp at time zone v_timezone;
  v_end := (v_today + 1)::timestamp at time zone v_timezone;

  if p_kind = 'new_customers' then
    return query
      select relationship.id,
             relationship.first_seen_at,
             coalesce(nullif(btrim(profile.full_name), ''), 'Cliente'),
             null::text,
             null::text,
             null::text,
             null::text,
             null::numeric,
             null::numeric
        from public.client_shop_relationships relationship
        left join public.profiles profile
          on profile.user_id = relationship.client_id
       where relationship.barber_shop_id = p_barber_shop_id
         and relationship.first_seen_at >= v_start
         and relationship.first_seen_at < v_end
       order by relationship.first_seen_at desc
       limit 500;
    return;
  end if;

  return query
    select appointment.id,
           appointment.starts_at,
           coalesce(nullif(btrim(profile.full_name), ''), 'Cliente agendado'),
           service.name,
           barber.name,
           appointment.status::text,
           appointment.cancelled_reason,
           appointment.total_price,
           coalesce(payment_totals.paid_amount, 0)::numeric
      from public.appointments appointment
      join public.services service
        on service.id = appointment.service_id
       and service.barber_shop_id = appointment.barber_shop_id
      join public.barbers barber
        on barber.id = appointment.barber_id
       and barber.barber_shop_id = appointment.barber_shop_id
      left join public.profiles profile
        on profile.user_id = appointment.client_id
      left join lateral (
        select sum(payment.amount) as paid_amount
          from public.payments payment
         where payment.appointment_id = appointment.id
           and payment.barber_shop_id = appointment.barber_shop_id
           and payment.status = 'paid'
      ) payment_totals on true
     where appointment.barber_shop_id = p_barber_shop_id
       and appointment.starts_at >= v_start
       and appointment.starts_at < v_end
       and (
         (p_kind = 'appointments' and appointment.status <> 'cancelled')
         or (p_kind = 'cancelled' and appointment.status = 'cancelled')
         or (p_kind = 'completed' and appointment.status = 'completed')
       )
     order by appointment.starts_at desc
     limit 500;
end;
$$;

revoke all on function public.get_owner_dashboard_details_v2(uuid, integer, text)
  from public, anon;
grant execute on function public.get_owner_dashboard_details_v2(uuid, integer, text)
  to authenticated;

notify pgrst, 'reload schema';
commit;
