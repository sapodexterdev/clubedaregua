-- Clube da Regua - solicitacoes publicas de agendamento
-- Execute este arquivo no Supabase depois do schema principal.

create table if not exists public.booking_requests (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  barber_id uuid not null references public.barbers(id) on delete restrict,
  service_id uuid not null references public.services(id) on delete restrict,
  requested_date date not null,
  requested_time time not null,
  customer_name text not null,
  customer_phone text not null,
  status text not null default 'new'
    check (status in ('new', 'contacted', 'converted', 'cancelled')),
  total_price numeric(10,2) not null default 0 check (total_price >= 0),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.booking_requests enable row level security;

grant insert on public.booking_requests to anon, authenticated;
grant select, update on public.booking_requests to authenticated;

drop trigger if exists set_booking_requests_updated_at on public.booking_requests;
create trigger set_booking_requests_updated_at before update on public.booking_requests
for each row execute function public.set_updated_at();

create index if not exists idx_booking_requests_shop_created
on public.booking_requests(barber_shop_id, created_at desc);

drop policy if exists booking_requests_insert_public on public.booking_requests;
create policy booking_requests_insert_public on public.booking_requests
for insert
with check (
  status = 'new'
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

drop policy if exists booking_requests_read_staff on public.booking_requests;
create policy booking_requests_read_staff on public.booking_requests
for select
using (public.is_shop_member(barber_shop_id) or public.is_platform_admin());

drop policy if exists booking_requests_update_staff on public.booking_requests;
create policy booking_requests_update_staff on public.booking_requests
for update
using (public.is_shop_member(barber_shop_id) or public.is_platform_admin())
with check (public.is_shop_member(barber_shop_id) or public.is_platform_admin());
