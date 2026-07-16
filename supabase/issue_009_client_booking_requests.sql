-- ISSUE-009 - Agenda real e privada do cliente
-- Execute no SQL Editor do Supabase antes de testar a UI-011.

alter table public.booking_requests
add column if not exists client_id uuid references public.users(id) on delete set null;

alter table public.booking_requests
alter column client_id set default auth.uid();

create index if not exists idx_booking_requests_client_date
on public.booking_requests(client_id, requested_date desc, requested_time desc);

drop policy if exists booking_requests_read_client on public.booking_requests;
create policy booking_requests_read_client on public.booking_requests
for select to authenticated
using (auth.uid() = client_id);

drop policy if exists booking_requests_cancel_client on public.booking_requests;
create policy booking_requests_cancel_client on public.booking_requests
for update to authenticated
using (
  auth.uid() = client_id
  and status in ('new', 'contacted')
)
with check (
  auth.uid() = client_id
  and status = 'cancelled'
);

-- Garante que solicitações autenticadas futuras sejam vinculadas ao próprio usuário.
drop policy if exists booking_requests_insert_public on public.booking_requests;
create policy booking_requests_insert_public on public.booking_requests
for insert
with check (
  status = 'new'
  and (client_id is null or client_id = auth.uid())
  and exists (
    select 1 from public.barber_shops shop
    where shop.id = barber_shop_id and shop.is_active = true
  )
  and exists (
    select 1 from public.barbers barber
    where barber.id = barber_id
      and barber.barber_shop_id = booking_requests.barber_shop_id
      and barber.is_active = true
  )
  and exists (
    select 1 from public.services service
    where service.id = service_id
      and service.barber_shop_id = booking_requests.barber_shop_id
      and service.is_active = true
  )
);
