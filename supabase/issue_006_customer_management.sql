-- Clube da Regua - gestao de clientes
-- Execute no Supabase para liberar dados de clientes para membros da barbearia.

drop view if exists public.management_client_appointments;
drop view if exists public.management_clients;

create or replace view public.management_clients as
select
  csr.id as relationship_id,
  csr.barber_shop_id,
  csr.client_id,
  csr.first_seen_at,
  csr.last_appointment_at,
  csr.notes,
  csr.is_blocked,
  users.email,
  users.is_active as user_is_active,
  profiles.full_name,
  profiles.phone,
  profiles.avatar_url,
  profiles.created_at as profile_created_at
from public.client_shop_relationships csr
join public.users on users.id = csr.client_id
left join public.profiles on profiles.user_id = csr.client_id
where
  auth.uid() = csr.client_id
  or public.is_shop_member(csr.barber_shop_id)
  or public.is_platform_admin();

create or replace view public.management_client_appointments as
select
  appointments.id,
  appointments.barber_shop_id,
  appointments.client_id,
  appointments.starts_at,
  appointments.status,
  appointments.notes,
  services.name as service_name,
  barbers.name as barber_name
from public.appointments
join public.services on services.id = appointments.service_id
join public.barbers on barbers.id = appointments.barber_id
where
  auth.uid() = appointments.client_id
  or public.is_shop_member(appointments.barber_shop_id)
  or public.is_platform_admin();

grant select on public.management_clients to authenticated;
grant select on public.management_client_appointments to authenticated;

drop policy if exists profiles_read_shop_staff on public.profiles;
create policy profiles_read_shop_staff on public.profiles
for select using (
  exists (
    select 1
    from public.client_shop_relationships csr
    where csr.client_id = profiles.user_id
      and public.is_shop_member(csr.barber_shop_id)
  )
  or public.is_platform_admin()
);

drop policy if exists profiles_update_shop_staff on public.profiles;
create policy profiles_update_shop_staff on public.profiles
for update using (
  exists (
    select 1
    from public.client_shop_relationships csr
    where csr.client_id = profiles.user_id
      and public.is_shop_member(csr.barber_shop_id)
  )
  or public.is_platform_admin()
)
with check (
  exists (
    select 1
    from public.client_shop_relationships csr
    where csr.client_id = profiles.user_id
      and public.is_shop_member(csr.barber_shop_id)
  )
  or public.is_platform_admin()
);
