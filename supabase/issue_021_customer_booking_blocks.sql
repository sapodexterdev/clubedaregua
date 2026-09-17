-- ISSUE-021 - Bloqueio de agendamento por cliente.
-- Somente o dono pode bloquear de forma geral ou para um barbeiro especifico.

create table if not exists public.client_booking_blocks (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  client_id uuid references public.users(id) on delete cascade,
  customer_phone_digits text,
  barber_id uuid references public.barbers(id) on delete cascade,
  blocked_by uuid not null references public.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  check (client_id is not null or nullif(customer_phone_digits, '') is not null),
  check (
    customer_phone_digits is null
    or customer_phone_digits = regexp_replace(customer_phone_digits, '[^0-9]', '', 'g')
  )
);

create unique index if not exists idx_client_booking_blocks_identity_scope
on public.client_booking_blocks (
  barber_shop_id,
  coalesce(client_id, '00000000-0000-0000-0000-000000000000'::uuid),
  coalesce(customer_phone_digits, ''),
  coalesce(barber_id, '00000000-0000-0000-0000-000000000000'::uuid)
);

create index if not exists idx_client_booking_blocks_lookup
on public.client_booking_blocks(barber_shop_id, client_id, customer_phone_digits, barber_id);

alter table public.client_booking_blocks enable row level security;

grant select on public.client_booking_blocks to authenticated;
revoke insert, update, delete on public.client_booking_blocks
from anon, authenticated;

drop policy if exists client_booking_blocks_read_owner
on public.client_booking_blocks;
create policy client_booking_blocks_read_owner
on public.client_booking_blocks
for select to authenticated
using (
  public.is_platform_admin()
  or public.is_shop_member(
    barber_shop_id,
    array['owner']::public.shop_member_role[]
  )
  or exists (
    select 1
    from public.barber_shops shop
    where shop.id = barber_shop_id
      and shop.owner_id = auth.uid()
  )
);

create or replace function public.set_client_booking_block(
  p_barber_shop_id uuid,
  p_client_id uuid,
  p_customer_phone text,
  p_barber_id uuid,
  p_blocked boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  phone_digits text := nullif(regexp_replace(coalesce(p_customer_phone, ''), '[^0-9]', '', 'g'), '');
begin
  if not (
    public.is_platform_admin()
    or public.is_shop_member(
      p_barber_shop_id,
      array['owner']::public.shop_member_role[]
    )
    or exists (
      select 1
      from public.barber_shops shop
      where shop.id = p_barber_shop_id
        and shop.owner_id = auth.uid()
    )
  ) then
    raise exception 'Somente o dono pode bloquear agendamentos de clientes.';
  end if;

  if p_client_id is null and phone_digits is null then
    raise exception 'Cliente sem identificacao valida para bloqueio.';
  end if;

  if p_barber_id is not null and not exists (
    select 1
    from public.barbers barber
    where barber.id = p_barber_id
      and barber.barber_shop_id = p_barber_shop_id
  ) then
    raise exception 'Barbeiro invalido para esta barbearia.';
  end if;

  delete from public.client_booking_blocks block
  where block.barber_shop_id = p_barber_shop_id
    and (
      (p_client_id is not null and block.client_id = p_client_id)
      or (phone_digits is not null and block.customer_phone_digits = phone_digits)
    );

  if p_blocked then
    insert into public.client_booking_blocks (
      barber_shop_id,
      client_id,
      customer_phone_digits,
      barber_id,
      blocked_by
    ) values (
      p_barber_shop_id,
      p_client_id,
      phone_digits,
      p_barber_id,
      auth.uid()
    );
  end if;

  return true;
end;
$$;

create or replace function public.enforce_customer_booking_block()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  phone_digits text := nullif(regexp_replace(coalesce(new.customer_phone, ''), '[^0-9]', '', 'g'), '');
begin
  if exists (
    select 1
    from public.client_booking_blocks block
    where block.barber_shop_id = new.barber_shop_id
      and (block.barber_id is null or block.barber_id = new.barber_id)
      and (
        (new.client_id is not null and block.client_id = new.client_id)
        or (phone_digits is not null and block.customer_phone_digits = phone_digits)
      )
  ) then
    raise exception 'Cliente bloqueado para agendamentos nesta barbearia.';
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_customer_booking_block
on public.booking_requests;
create trigger enforce_customer_booking_block
before insert on public.booking_requests
for each row execute function public.enforce_customer_booking_block();

-- Converte os bloqueios gerais antigos para a nova regra efetiva.
insert into public.client_booking_blocks (
  barber_shop_id,
  client_id,
  blocked_by
)
select
  relationship.barber_shop_id,
  relationship.client_id,
  shop.owner_id
from public.client_shop_relationships relationship
join public.barber_shops shop on shop.id = relationship.barber_shop_id
where relationship.is_blocked = true
  and shop.owner_id is not null
  and not exists (
    select 1
    from public.client_booking_blocks block
    where block.barber_shop_id = relationship.barber_shop_id
      and block.client_id = relationship.client_id
      and block.barber_id is null
  );

update public.client_shop_relationships
set is_blocked = false
where is_blocked = true;

revoke all on function public.set_client_booking_block(uuid, uuid, text, uuid, boolean)
from public, anon, authenticated;
grant execute on function public.set_client_booking_block(uuid, uuid, text, uuid, boolean)
to authenticated;
revoke all on function public.enforce_customer_booking_block()
from public, anon, authenticated;

notify pgrst, 'reload schema';
