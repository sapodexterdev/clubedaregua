-- ISSUE-030 - Indicadores de comissão individual do barbeiro
begin;

alter table public.appointments
  add column if not exists completed_at timestamptz;

-- Backfill legado pela última referência disponível; novos registros recebem
-- o instante exato pela função complete_appointment definida nesta migration.
update public.appointments
   set completed_at = updated_at
 where status = 'completed'
   and completed_at is null;

create or replace function public.complete_appointment(p_appointment_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare appointment_row public.appointments%rowtype;
begin
  select * into appointment_row
    from public.appointments
   where id = p_appointment_id
   for update;
  if not found then raise exception 'Agendamento nao encontrado.'; end if;
  if not (public.is_shop_member(appointment_row.barber_shop_id)
          or public.is_platform_admin()) then
    raise exception 'Sem permissao para concluir este atendimento.';
  end if;
  if appointment_row.status = 'completed' then
    if appointment_row.completed_at is null then
      update public.appointments
         set completed_at = now()
       where id = appointment_row.id;
    end if;
    return true;
  end if;
  if appointment_row.status not in ('pending', 'confirmed') then
    raise exception 'Este atendimento nao pode ser concluido.';
  end if;

  update public.appointments
     set status = 'completed', completed_at = now()
   where id = appointment_row.id;
  return true;
end;
$$;

create or replace function public.get_barber_commission_metrics(
  p_barber_shop_id uuid,
  p_days integer default 7
)
returns table(
  completed_appointments bigint,
  production numeric,
  commission_percent numeric,
  commission numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_timezone text;
  v_today date;
  v_from date;
  v_start timestamptz;
  v_end timestamptz;
  v_barber_id uuid;
  v_commission_percent numeric(5,2);
  v_appointments bigint;
  v_production numeric;
begin
  if p_days is null or p_days not in (1, 7, 30) then
    raise exception 'Período inválido para os indicadores de comissão.';
  end if;

  if p_barber_shop_id is null then
    raise exception 'Barbearia não encontrada.';
  end if;

  select barber.id, barber.commission_percent, shop.timezone
    into v_barber_id, v_commission_percent, v_timezone
    from public.barbers barber
    join public.barber_shops shop on shop.id = barber.barber_shop_id
   where barber.barber_shop_id = p_barber_shop_id
     and barber.user_id = auth.uid()
     and barber.is_active = true
   limit 1;

  if v_barber_id is null then
    raise exception 'Acesso negado aos dados de comissão deste profissional.';
  end if;

  v_today := (now() at time zone coalesce(v_timezone, 'America/Sao_Paulo'))::date;
  v_from := v_today - (p_days - 1);
  v_start := v_from::timestamp at time zone coalesce(v_timezone, 'America/Sao_Paulo');
  v_end := (v_today + 1)::timestamp at time zone coalesce(v_timezone, 'America/Sao_Paulo');

  select count(*), coalesce(sum(appointment.total_price), 0)
    into v_appointments, v_production
    from public.appointments appointment
   where appointment.barber_shop_id = p_barber_shop_id
     and appointment.barber_id = v_barber_id
     and appointment.status = 'completed'
     and appointment.completed_at >= v_start
     and appointment.completed_at < v_end;

  return query select v_appointments,
                      v_production,
                      v_commission_percent,
                      round(v_production * v_commission_percent / 100, 2);
end;
$$;

revoke all on function public.get_barber_commission_metrics(uuid, integer)
  from public, anon;
grant execute on function public.get_barber_commission_metrics(uuid, integer)
  to authenticated;
revoke all on function public.complete_appointment(uuid) from public;
grant execute on function public.complete_appointment(uuid) to authenticated;

commit;
