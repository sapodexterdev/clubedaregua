-- ISSUE-026 - Aceite automático de convite pendente após login
-- Permite concluir a vinculação quando o profissional criou a conta sem
-- utilizar o link do convite, usando o e-mail autenticado como confirmação.

create or replace function public.accept_pending_shop_invitation()
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  invitation public.shop_invitations%rowtype;
  current_email text;
begin
  if auth.uid() is null then
    raise exception 'Faça login para aceitar o convite.';
  end if;

  select lower(email)
    into current_email
  from public.users
  where id = auth.uid();

  select invitation_row.*
    into invitation
  from public.shop_invitations invitation_row
  where lower(invitation_row.email) = current_email
    and invitation_row.status = 'pending'
  order by invitation_row.created_at desc
  limit 1
  for update;

  if invitation.id is null then
    return null;
  end if;

  if invitation.expires_at <= now() then
    update public.shop_invitations
    set status = 'expired', updated_at = now()
    where id = invitation.id;
    raise exception 'Este convite expirou. Solicite um novo convite.';
  end if;

  insert into public.shop_members (
    barber_shop_id, user_id, role, is_active, invited_by
  )
  values (
    invitation.barber_shop_id, auth.uid(), invitation.role, true,
    invitation.invited_by
  )
  on conflict (barber_shop_id, user_id) do update
  set role = excluded.role,
      is_active = true,
      invited_by = excluded.invited_by,
      updated_at = now();

  if invitation.role = 'barber' and invitation.barber_id is not null then
    update public.barbers
    set user_id = auth.uid(), is_active = true, updated_at = now()
    where id = invitation.barber_id
      and barber_shop_id = invitation.barber_shop_id;
  end if;

  update public.shop_invitations
  set status = 'accepted', accepted_at = now(), accepted_by = auth.uid(),
      updated_at = now()
  where id = invitation.id;

  return jsonb_build_object(
    'barber_shop_id', invitation.barber_shop_id,
    'barber_id', invitation.barber_id,
    'role', invitation.role,
    'already_accepted', false,
    'matched_by_email', true
  );
end;
$$;

revoke all on function public.accept_pending_shop_invitation() from public;
grant execute on function public.accept_pending_shop_invitation() to authenticated;
