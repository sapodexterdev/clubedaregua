-- ISSUE-025 - Isolamento dos clientes atendidos pelo barbeiro
--
-- O Dono continua usando as views de gestao e os RPCs de bloqueio existentes.
-- O modo Barbeiro deve consumir exclusivamente os dois RPCs abaixo. Eles
-- retornam apenas atendimentos concluidos atribuidos ao barbeiro autenticado.

begin;

create index if not exists idx_appointments_shop_barber_status_starts
on public.appointments(barber_shop_id, barber_id, status, starts_at desc);

create index if not exists idx_appointments_shop_client_status
on public.appointments(barber_shop_id, client_id, status)
where client_id is not null;

create index if not exists idx_barbers_shop_user
on public.barbers(barber_shop_id, user_id)
where user_id is not null;

-- Defesa adicional para os RPCs de bloqueio das issues 021/022: uma
-- identidade somente pode ser bloqueada dentro de uma loja onde ela exista.
create or replace function public.validate_client_booking_block_scope()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.client_id is not null and not exists (
    select 1
    from public.client_shop_relationships relationship
    where relationship.barber_shop_id = new.barber_shop_id
      and relationship.client_id = new.client_id
  ) then
    raise exception 'Cliente invalido para esta barbearia.';
  end if;

  if new.customer_phone_digits is not null and not (
    (
      new.client_id is not null
      and exists (
        select 1
        from public.profiles profile
        where profile.user_id = new.client_id
          and regexp_replace(
            coalesce(profile.phone, ''),
            '[^0-9]',
            '',
            'g'
          ) = new.customer_phone_digits
      )
    )
    or exists (
      select 1
      from public.booking_requests request
      where request.barber_shop_id = new.barber_shop_id
        and (new.client_id is null or request.client_id = new.client_id)
        and regexp_replace(
          coalesce(request.customer_phone, ''),
          '[^0-9]',
          '',
          'g'
        ) = new.customer_phone_digits
    )
  ) then
    raise exception 'Telefone do cliente invalido para esta barbearia.';
  end if;

  return new;
end;
$$;

drop trigger if exists validate_client_booking_block_scope
on public.client_booking_blocks;
create trigger validate_client_booking_block_scope
before insert or update on public.client_booking_blocks
for each row execute function public.validate_client_booking_block_scope();

revoke all on function public.validate_client_booking_block_scope()
from public, anon, authenticated;

create or replace function public.can_view_all_customer_data(
  target_shop_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_platform_admin()
    or public.is_shop_owner_or_manager(target_shop_id)
    or public.is_shop_member(
      target_shop_id,
      array['receptionist']::public.shop_member_role[]
    );
$$;

revoke all on function public.can_view_all_customer_data(uuid) from public;
revoke all on function public.can_view_all_customer_data(uuid) from anon;
grant execute on function public.can_view_all_customer_data(uuid)
to authenticated;

drop function if exists public.list_barber_customers(uuid, uuid);
create function public.list_barber_customers(
  p_barber_shop_id uuid,
  p_barber_id uuid
)
returns table (
  relationship_id text,
  barber_shop_id uuid,
  client_id text,
  first_seen_at timestamptz,
  last_appointment_at timestamptz,
  notes text,
  is_blocked boolean,
  email text,
  user_is_active boolean,
  full_name text,
  phone text,
  avatar_url text,
  profile_created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  with authorized_barber as (
    select barber.id, barber.barber_shop_id, barber.name
    from public.barbers barber
    where auth.uid() is not null
      and barber.id = p_barber_id
      and barber.barber_shop_id = p_barber_shop_id
      and barber.user_id = auth.uid()
      and barber.is_active = true
  ),
  attended as (
    select
      appointment.id,
      appointment.barber_shop_id,
      appointment.client_id,
      appointment.starts_at,
      request.customer_name,
      request.customer_phone,
      regexp_replace(
        coalesce(request.customer_phone, ''),
        '[^0-9]',
        '',
        'g'
      ) as customer_phone_digits
    from authorized_barber authorized
    join public.appointments appointment
      on appointment.barber_shop_id = authorized.barber_shop_id
     and appointment.barber_id = authorized.id
     and appointment.status = 'completed'::public.appointment_status
    left join public.booking_requests request
      on request.appointment_id = appointment.id
     and request.barber_shop_id = appointment.barber_shop_id
     and request.barber_id = appointment.barber_id
  ),
  registered_clients as (
    select
      attended.client_id,
      min(attended.starts_at) as first_seen_at,
      max(attended.starts_at) as last_appointment_at
    from attended
    where attended.client_id is not null
    group by attended.client_id
  ),
  registered_rows as (
    select
      ''::text as relationship_id,
      p_barber_shop_id as barber_shop_id,
      registered.client_id::text as client_id,
      registered.first_seen_at,
      registered.last_appointment_at,
      ''::text as notes,
      false as is_blocked,
      app_user.email,
      app_user.is_active as user_is_active,
      coalesce(
        nullif(trim(profile.full_name), ''),
        nullif(trim(latest_request.customer_name), ''),
        app_user.email,
        'Cliente'
      ) as full_name,
      coalesce(
        nullif(trim(profile.phone), ''),
        nullif(trim(latest_request.customer_phone), ''),
        ''
      ) as phone,
      coalesce(profile.avatar_url, '') as avatar_url,
      profile.created_at as profile_created_at
    from registered_clients registered
    join public.users app_user on app_user.id = registered.client_id
    left join public.profiles profile on profile.user_id = registered.client_id
    left join lateral (
      select attended.customer_name, attended.customer_phone
      from attended
      where attended.client_id = registered.client_id
        and (
          nullif(trim(attended.customer_name), '') is not null
          or nullif(trim(attended.customer_phone), '') is not null
        )
      order by attended.starts_at desc, attended.id desc
      limit 1
    ) latest_request on true
  ),
  guest_clients as (
    select
      attended.customer_phone_digits,
      min(attended.starts_at) as first_seen_at,
      max(attended.starts_at) as last_appointment_at
    from attended
    where attended.client_id is null
      and attended.customer_phone_digits <> ''
    group by attended.customer_phone_digits
  ),
  guest_rows as (
    select
      ''::text as relationship_id,
      p_barber_shop_id as barber_shop_id,
      ('booking:' || guest.customer_phone_digits)::text as client_id,
      guest.first_seen_at,
      guest.last_appointment_at,
      ''::text as notes,
      false as is_blocked,
      ''::text as email,
      true as user_is_active,
      coalesce(
        nullif(trim(latest_request.customer_name), ''),
        'Cliente'
      ) as full_name,
      coalesce(latest_request.customer_phone, '') as phone,
      ''::text as avatar_url,
      guest.first_seen_at as profile_created_at
    from guest_clients guest
    left join lateral (
      select attended.customer_name, attended.customer_phone
      from attended
      where attended.client_id is null
        and attended.customer_phone_digits = guest.customer_phone_digits
      order by attended.starts_at desc, attended.id desc
      limit 1
    ) latest_request on true
  )
  select scoped.*
  from (
    select * from registered_rows
    union all
    select * from guest_rows
  ) scoped
  order by lower(scoped.full_name), scoped.client_id;
$$;

revoke all on function public.list_barber_customers(uuid, uuid) from public;
revoke all on function public.list_barber_customers(uuid, uuid) from anon;
revoke all on function public.list_barber_customers(uuid, uuid)
from authenticated;
grant execute on function public.list_barber_customers(uuid, uuid)
to authenticated;

drop function if exists public.list_barber_customer_appointments(uuid, uuid);
create function public.list_barber_customer_appointments(
  p_barber_shop_id uuid,
  p_barber_id uuid
)
returns table (
  id text,
  client_id text,
  starts_at timestamptz,
  status text,
  notes text,
  service_name text,
  barber_name text
)
language sql
stable
security definer
set search_path = public
as $$
  with authorized_barber as (
    select barber.id, barber.barber_shop_id, barber.name
    from public.barbers barber
    where auth.uid() is not null
      and barber.id = p_barber_id
      and barber.barber_shop_id = p_barber_shop_id
      and barber.user_id = auth.uid()
      and barber.is_active = true
  )
  select
    appointment.id::text as id,
    case
      when appointment.client_id is not null
        then appointment.client_id::text
      else 'booking:' || regexp_replace(
        coalesce(request.customer_phone, ''),
        '[^0-9]',
        '',
        'g'
      )
    end as client_id,
    appointment.starts_at,
    appointment.status::text as status,
    coalesce(appointment.notes, '') as notes,
    service.name as service_name,
    authorized.name as barber_name
  from authorized_barber authorized
  join public.appointments appointment
    on appointment.barber_shop_id = authorized.barber_shop_id
   and appointment.barber_id = authorized.id
   and appointment.status = 'completed'::public.appointment_status
  join public.services service
    on service.id = appointment.service_id
   and service.barber_shop_id = appointment.barber_shop_id
  left join public.booking_requests request
    on request.appointment_id = appointment.id
   and request.barber_shop_id = appointment.barber_shop_id
   and request.barber_id = appointment.barber_id
  where appointment.client_id is not null
     or regexp_replace(
       coalesce(request.customer_phone, ''),
       '[^0-9]',
       '',
       'g'
     ) <> ''
  order by appointment.starts_at desc, appointment.id desc;
$$;

revoke all on function public.list_barber_customer_appointments(uuid, uuid)
from public;
revoke all on function public.list_barber_customer_appointments(uuid, uuid)
from anon;
revoke all on function public.list_barber_customer_appointments(uuid, uuid)
from authenticated;
grant execute on function public.list_barber_customer_appointments(uuid, uuid)
to authenticated;

-- O barbeiro pode consultar somente pedidos atribuidos ao seu proprio cadastro.
-- Dono, gerente, recepcao e administrador preservam a visao integral da loja.
drop policy if exists booking_requests_read_staff
on public.booking_requests;
create policy booking_requests_read_staff
on public.booking_requests
for select
to authenticated
using (
  public.can_view_all_customer_data(barber_shop_id)
  or exists (
    select 1
    from public.barbers barber
    where barber.id = booking_requests.barber_id
      and barber.barber_shop_id = booking_requests.barber_shop_id
      and barber.user_id = auth.uid()
      and barber.is_active = true
  )
);

drop policy if exists appointments_read_involved
on public.appointments;
create policy appointments_read_involved
on public.appointments
for select
to authenticated
using (
  auth.uid() = client_id
  or public.can_view_all_customer_data(barber_shop_id)
  or exists (
    select 1
    from public.barbers barber
    where barber.id = appointments.barber_id
      and barber.barber_shop_id = appointments.barber_shop_id
      and barber.user_id = auth.uid()
      and barber.is_active = true
  )
);

-- A antiga policy FOR ALL tambem concedia SELECT a qualquer membro da loja.
-- As escritas de relacionamento passam a ser exclusivas da gestao.
drop policy if exists client_relationships_read
on public.client_shop_relationships;
drop policy if exists client_relationships_manage_staff
on public.client_shop_relationships;
drop policy if exists client_relationships_insert_management
on public.client_shop_relationships;
drop policy if exists client_relationships_update_management
on public.client_shop_relationships;
drop policy if exists client_relationships_delete_management
on public.client_shop_relationships;

create policy client_relationships_read
on public.client_shop_relationships
for select
to authenticated
using (
  auth.uid() = client_id
  or public.can_view_all_customer_data(barber_shop_id)
);

create policy client_relationships_insert_management
on public.client_shop_relationships
for insert
to authenticated
with check (public.is_shop_owner_or_manager(barber_shop_id));

create policy client_relationships_update_management
on public.client_shop_relationships
for update
to authenticated
using (public.is_shop_owner_or_manager(barber_shop_id))
with check (public.is_shop_owner_or_manager(barber_shop_id));

create policy client_relationships_delete_management
on public.client_shop_relationships
for delete
to authenticated
using (public.is_shop_owner_or_manager(barber_shop_id));

drop policy if exists profiles_read_shop_staff
on public.profiles;
create policy profiles_read_shop_staff
on public.profiles
for select
to authenticated
using (
  exists (
    select 1
    from public.client_shop_relationships relationship
    where relationship.client_id = profiles.user_id
      and public.can_view_all_customer_data(relationship.barber_shop_id)
  )
  or public.is_platform_admin()
);

drop policy if exists profiles_update_shop_staff
on public.profiles;
create policy profiles_update_shop_staff
on public.profiles
for update
to authenticated
using (
  exists (
    select 1
    from public.client_shop_relationships relationship
    where relationship.client_id = profiles.user_id
      and public.is_shop_owner_or_manager(relationship.barber_shop_id)
  )
  or public.is_platform_admin()
)
with check (
  exists (
    select 1
    from public.client_shop_relationships relationship
    where relationship.client_id = profiles.user_id
      and public.is_shop_owner_or_manager(relationship.barber_shop_id)
  )
  or public.is_platform_admin()
);

drop view if exists public.management_client_appointments;
drop view if exists public.management_clients;

create view public.management_clients
with (security_barrier = true)
as
select
  relationship.id as relationship_id,
  relationship.barber_shop_id,
  relationship.client_id,
  relationship.first_seen_at,
  relationship.last_appointment_at,
  case
    when public.can_view_all_customer_data(relationship.barber_shop_id)
      then relationship.notes
    else ''::text
  end as notes,
  case
    when public.can_view_all_customer_data(relationship.barber_shop_id)
      then relationship.is_blocked
    else false
  end as is_blocked,
  app_user.email,
  app_user.is_active as user_is_active,
  profile.full_name,
  profile.phone,
  profile.avatar_url,
  profile.created_at as profile_created_at
from public.client_shop_relationships relationship
join public.users app_user on app_user.id = relationship.client_id
left join public.profiles profile on profile.user_id = relationship.client_id
where
  auth.uid() = relationship.client_id
  or public.can_view_all_customer_data(relationship.barber_shop_id)
  or exists (
    select 1
    from public.appointments appointment
    join public.barbers barber
      on barber.id = appointment.barber_id
     and barber.barber_shop_id = appointment.barber_shop_id
    where appointment.barber_shop_id = relationship.barber_shop_id
      and appointment.client_id = relationship.client_id
      and appointment.status = 'completed'::public.appointment_status
      and barber.user_id = auth.uid()
      and barber.is_active = true
  );

create view public.management_client_appointments
with (security_barrier = true)
as
select
  appointment.id,
  appointment.barber_shop_id,
  appointment.client_id,
  appointment.starts_at,
  appointment.status,
  appointment.notes,
  service.name as service_name,
  barber.name as barber_name
from public.appointments appointment
join public.services service on service.id = appointment.service_id
join public.barbers barber on barber.id = appointment.barber_id
where
  auth.uid() = appointment.client_id
  or public.can_view_all_customer_data(appointment.barber_shop_id)
  or (
    barber.barber_shop_id = appointment.barber_shop_id
    and barber.user_id = auth.uid()
    and barber.is_active = true
  );

grant select on public.management_clients to authenticated;
grant select on public.management_client_appointments to authenticated;

notify pgrst, 'reload schema';

commit;
