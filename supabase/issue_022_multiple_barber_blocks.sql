-- ISSUE-022 - Permite bloquear um cliente para varios barbeiros.

create or replace function public.set_client_booking_blocks(
  p_barber_shop_id uuid,
  p_client_id uuid,
  p_customer_phone text,
  p_barber_ids uuid[],
  p_blocked boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  phone_digits text := nullif(regexp_replace(coalesce(p_customer_phone, ''), '[^0-9]', '', 'g'), '');
  selected_barber_id uuid;
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

  if exists (
    select 1
    from unnest(coalesce(p_barber_ids, array[]::uuid[])) as selected(id)
    where not exists (
      select 1
      from public.barbers barber
      where barber.id = selected.id
        and barber.barber_shop_id = p_barber_shop_id
    )
  ) then
    raise exception 'Um dos barbeiros e invalido para esta barbearia.';
  end if;

  delete from public.client_booking_blocks block
  where block.barber_shop_id = p_barber_shop_id
    and (
      (p_client_id is not null and block.client_id = p_client_id)
      or (phone_digits is not null and block.customer_phone_digits = phone_digits)
    );

  if not p_blocked then
    return true;
  end if;

  if coalesce(array_length(p_barber_ids, 1), 0) = 0 then
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
      null,
      auth.uid()
    );
    return true;
  end if;

  foreach selected_barber_id in array p_barber_ids loop
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
      selected_barber_id,
      auth.uid()
    );
  end loop;

  return true;
end;
$$;

revoke all on function public.set_client_booking_blocks(uuid, uuid, text, uuid[], boolean)
from public, anon, authenticated;
grant execute on function public.set_client_booking_blocks(uuid, uuid, text, uuid[], boolean)
to authenticated;

notify pgrst, 'reload schema';
