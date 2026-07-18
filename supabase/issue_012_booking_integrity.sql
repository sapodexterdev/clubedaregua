-- ISSUE-012 - Integridade da agenda e disponibilidade publica
-- Execute este arquivo no SQL Editor do Supabase antes de validar o fluxo.

create or replace view public.appointment_availability as
select
  appointment.id,
  appointment.barber_shop_id,
  appointment.barber_id,
  appointment.starts_at,
  appointment.ends_at,
  appointment.status
from public.appointments appointment
where appointment.status in ('pending', 'confirmed');

grant select on public.appointment_availability to anon, authenticated;

create or replace function public.prevent_booking_request_conflict()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  service_duration integer;
  shop_timezone text;
  requested_start timestamptz;
  requested_end timestamptz;
begin
  if new.status not in ('new', 'contacted') then
    return new;
  end if;

  select service.duration_minutes
  into service_duration
  from public.services service
  where service.id = new.service_id
    and service.barber_shop_id = new.barber_shop_id
    and service.is_active = true;

  if service_duration is null then
    raise exception 'Servico indisponivel para agendamento.';
  end if;

  select coalesce(nullif(shop.timezone, ''), 'America/Sao_Paulo')
  into shop_timezone
  from public.barber_shops shop
  where shop.id = new.barber_shop_id
    and shop.is_active = true;

  if shop_timezone is null then
    raise exception 'Barbearia indisponivel para agendamento.';
  end if;

  requested_start := (new.requested_date + new.requested_time) at time zone shop_timezone;
  requested_end := requested_start + make_interval(mins => service_duration);

  perform pg_advisory_xact_lock(hashtextextended(new.barber_id::text, 0));

  if exists (
    select 1
    from public.appointments appointment
    where appointment.barber_id = new.barber_id
      and appointment.status in ('pending', 'confirmed')
      and appointment.starts_at < requested_end
      and appointment.ends_at > requested_start
  ) then
    raise exception 'O horario escolhido ja esta ocupado.';
  end if;

  if exists (
    select 1
    from public.booking_requests request
    join public.services service on service.id = request.service_id
    where request.barber_id = new.barber_id
      and request.id is distinct from new.id
      and request.status in ('new', 'contacted')
      and (
        (request.requested_date + request.requested_time) at time zone shop_timezone
      ) < requested_end
      and (
        (request.requested_date + request.requested_time) at time zone shop_timezone
        + make_interval(mins => service.duration_minutes)
      ) > requested_start
  ) then
    raise exception 'O horario escolhido ja possui uma solicitacao ativa.';
  end if;

  return new;
end;
$$;

drop trigger if exists prevent_booking_request_conflict on public.booking_requests;
create trigger prevent_booking_request_conflict
before insert or update of barber_id, service_id, requested_date, requested_time, status
on public.booking_requests
for each row execute function public.prevent_booking_request_conflict();
