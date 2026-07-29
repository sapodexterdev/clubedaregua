-- ISSUE-011 - Conversao atomica de solicitacao em agendamento real
-- Execute este arquivo no SQL Editor do Supabase antes de testar na Gestao.

alter table public.booking_requests
add column if not exists appointment_id uuid
references public.appointments(id) on delete set null;

create unique index if not exists idx_booking_requests_appointment
on public.booking_requests(appointment_id)
where appointment_id is not null;

create or replace function public.accept_booking_request(p_request_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  request_row public.booking_requests%rowtype;
  service_duration integer;
  shop_timezone text;
  appointment_start timestamptz;
  appointment_end timestamptz;
  created_appointment_id uuid;
begin
  select * into request_row
  from public.booking_requests
  where id = p_request_id
  for update;

  if not found then raise exception 'Solicitacao nao encontrada.'; end if;
  if not (public.is_shop_member(request_row.barber_shop_id) or public.is_platform_admin()) then
    raise exception 'Sem permissao para aceitar esta solicitacao.';
  end if;
  if request_row.appointment_id is not null then return request_row.appointment_id; end if;
  if request_row.status not in ('new', 'contacted') then
    raise exception 'Esta solicitacao nao pode mais ser aceita.';
  end if;

  select duration_minutes into service_duration
  from public.services
  where id = request_row.service_id
    and barber_shop_id = request_row.barber_shop_id
    and is_active = true;
  if service_duration is null then raise exception 'Servico indisponivel para agendamento.'; end if;

  select timezone into shop_timezone from public.barber_shops where id = request_row.barber_shop_id;
  shop_timezone := coalesce(nullif(shop_timezone, ''), 'America/Sao_Paulo');
  appointment_start := (request_row.requested_date + request_row.requested_time) at time zone shop_timezone;
  appointment_end := appointment_start + make_interval(mins => service_duration);

  perform pg_advisory_xact_lock(hashtextextended(request_row.barber_id::text, 0));
  if exists (
    select 1 from public.appointments appointment
    where appointment.barber_id = request_row.barber_id
      and appointment.status in ('pending', 'confirmed')
      and appointment.starts_at < appointment_end
      and appointment.ends_at > appointment_start
  ) then
    raise exception 'O horario escolhido ja esta ocupado.';
  end if;

  insert into public.appointments (
    barber_shop_id, client_id, barber_id, service_id, starts_at, ends_at,
    status, total_price, notes, created_by
  ) values (
    request_row.barber_shop_id, request_row.client_id, request_row.barber_id,
    request_row.service_id, appointment_start, appointment_end, 'confirmed',
    request_row.total_price, request_row.notes, auth.uid()
  ) returning id into created_appointment_id;

  update public.booking_requests
  set status = 'converted', appointment_id = created_appointment_id
  where id = request_row.id;

  return created_appointment_id;
end;
$$;

create or replace function public.complete_appointment(p_appointment_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare appointment_row public.appointments%rowtype;
begin
  select * into appointment_row from public.appointments where id = p_appointment_id for update;
  if not found then raise exception 'Agendamento nao encontrado.'; end if;
  if not (public.is_shop_member(appointment_row.barber_shop_id) or public.is_platform_admin()) then
    raise exception 'Sem permissao para concluir este atendimento.';
  end if;
  if appointment_row.status = 'completed' then return true; end if;
  if appointment_row.status not in ('pending', 'confirmed') then
    raise exception 'Este atendimento nao pode ser concluido.';
  end if;

  update public.appointments set status = 'completed' where id = appointment_row.id;
  return true;
end;
$$;

create or replace function public.notify_booking_request_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'converted'
    and old.status is distinct from new.status
    and new.client_id is not null
    and not exists (
      select 1 from public.notifications notification
      where notification.user_id = new.client_id
        and notification.data->>'type' = 'appointment_confirmed'
        and notification.data->>'booking_request_id' = new.id::text
    )
  then
    insert into public.notifications (barber_shop_id, user_id, title, message, data)
    values (
      new.barber_shop_id,
      new.client_id,
      'Agendamento confirmado',
      'Seu horario foi confirmado pela barbearia.',
      jsonb_build_object(
        'type', 'appointment_confirmed',
        'appointment_id', new.appointment_id,
        'booking_request_id', new.id
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists notify_booking_request_status on public.booking_requests;
create trigger notify_booking_request_status
after update of status on public.booking_requests
for each row execute function public.notify_booking_request_status_change();

create or replace function public.notify_appointment_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'completed'
    and old.status is distinct from new.status
    and new.client_id is not null
    and not exists (
      select 1 from public.notifications notification
      where notification.user_id = new.client_id
        and notification.data->>'type' = 'appointment_completed'
        and notification.data->>'appointment_id' = new.id::text
    )
  then
    insert into public.notifications (barber_shop_id, user_id, title, message, data)
    values (
      new.barber_shop_id,
      new.client_id,
      'Atendimento concluido',
      'Esperamos que tenha gostado. Sua avaliacao ajuda todo o Clube.',
      jsonb_build_object(
        'type', 'appointment_completed',
        'appointment_id', new.id
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists notify_appointment_status on public.appointments;
create trigger notify_appointment_status
after update of status on public.appointments
for each row execute function public.notify_appointment_status_change();

-- Recupera eventos antigos que mudaram de status antes da criacao dos gatilhos.
insert into public.notifications (barber_shop_id, user_id, title, message, data)
select
  request.barber_shop_id,
  request.client_id,
  'Agendamento confirmado',
  'Seu horario foi confirmado pela barbearia.',
  jsonb_build_object(
    'type', 'appointment_confirmed',
    'appointment_id', request.appointment_id,
    'booking_request_id', request.id
  )
from public.booking_requests request
where request.status = 'converted'
  and request.client_id is not null
  and not exists (
    select 1 from public.notifications notification
    where notification.user_id = request.client_id
      and notification.data->>'type' = 'appointment_confirmed'
      and notification.data->>'booking_request_id' = request.id::text
  );

insert into public.notifications (barber_shop_id, user_id, title, message, data)
select
  appointment.barber_shop_id,
  appointment.client_id,
  'Atendimento concluido',
  'Esperamos que tenha gostado. Sua avaliacao ajuda todo o Clube.',
  jsonb_build_object(
    'type', 'appointment_completed',
    'appointment_id', appointment.id
  )
from public.appointments appointment
where appointment.status = 'completed'
  and appointment.client_id is not null
  and not exists (
    select 1 from public.notifications notification
    where notification.user_id = appointment.client_id
      and notification.data->>'type' = 'appointment_completed'
      and notification.data->>'appointment_id' = appointment.id::text
  );

revoke all on function public.accept_booking_request(uuid) from public;
revoke all on function public.complete_appointment(uuid) from public;
grant execute on function public.accept_booking_request(uuid) to authenticated;
grant execute on function public.complete_appointment(uuid) to authenticated;
