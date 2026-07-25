-- ISSUE-018 - Agendamento rápido sem cadastro
-- Mantém client_id opcional e protege a entrada pública com validações mínimas.

alter table public.booking_requests
  alter column client_id drop not null,
  alter column client_id set default auth.uid();

alter table public.booking_requests
  add column if not exists public_reference uuid not null default gen_random_uuid();

create unique index if not exists idx_booking_requests_public_reference
on public.booking_requests(public_reference);

alter table public.booking_requests
  drop constraint if exists booking_requests_customer_name_length,
  add constraint booking_requests_customer_name_length
    check (char_length(trim(customer_name)) between 3 and 120) not valid;

alter table public.booking_requests
  drop constraint if exists booking_requests_customer_phone_digits,
  add constraint booking_requests_customer_phone_digits
    check (
      char_length(regexp_replace(customer_phone, '[^0-9]', '', 'g'))
      between 10 and 11
    ) not valid;

grant insert on public.booking_requests to anon, authenticated;

drop policy if exists booking_requests_insert_public
on public.booking_requests;
create policy booking_requests_insert_public
on public.booking_requests
for insert
to anon, authenticated
with check (
  status = 'new'
  and (client_id is null or client_id = auth.uid())
  and char_length(trim(customer_name)) between 3 and 120
  and char_length(regexp_replace(customer_phone, '[^0-9]', '', 'g'))
      between 10 and 11
  and exists (
    select 1
    from public.barber_shops shop
    where shop.id = barber_shop_id
      and shop.is_active = true
  )
  and exists (
    select 1
    from public.barbers barber
    where barber.id = barber_id
      and barber.barber_shop_id = booking_requests.barber_shop_id
      and barber.is_active = true
  )
  and exists (
    select 1
    from public.services service
    where service.id = service_id
      and service.barber_shop_id = booking_requests.barber_shop_id
      and service.is_active = true
  )
);

comment on column public.booking_requests.public_reference is
  'Protocolo público aleatório da solicitação, sem expor IDs sequenciais.';
