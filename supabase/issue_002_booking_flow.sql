-- ISSUE-002 - Fluxo real de agendamento
-- Execute no SQL Editor do Supabase antes de testar o app Cliente.

create unique index if not exists idx_booking_requests_no_time_conflict
on public.booking_requests(barber_id, requested_date, requested_time)
where status in ('new', 'contacted');

create or replace view public.booking_request_availability as
select
  booking_requests.id,
  booking_requests.barber_shop_id,
  booking_requests.barber_id,
  booking_requests.service_id,
  services.duration_minutes,
  booking_requests.requested_date,
  booking_requests.requested_time,
  booking_requests.status
from public.booking_requests
join public.services on services.id = booking_requests.service_id
where status in ('new', 'contacted');

grant select on public.booking_request_availability to anon, authenticated;

create or replace view public.appointment_availability as
select
  id,
  barber_shop_id,
  barber_id,
  starts_at,
  ends_at,
  status
from public.appointments
where status in ('pending', 'confirmed');

grant select on public.appointment_availability to anon, authenticated;
