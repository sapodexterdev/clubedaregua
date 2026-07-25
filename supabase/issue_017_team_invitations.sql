-- ISSUE-017 - Equipe e convites profissionais
-- Fluxo seguro para vincular barbeiros, gerentes e recepcionistas a uma unidade.

create table if not exists public.shop_invitations (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  barber_id uuid references public.barbers(id) on delete cascade,
  email text not null,
  role public.shop_member_role not null default 'barber',
  token_hash text not null unique,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'revoked', 'expired')),
  invited_by uuid not null references public.users(id) on delete cascade,
  expires_at timestamptz not null default (now() + interval '7 days'),
  accepted_at timestamptz,
  accepted_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_shop_invitations_pending_email
on public.shop_invitations(barber_shop_id, lower(email))
where status = 'pending';

create index if not exists idx_shop_invitations_shop_status
on public.shop_invitations(barber_shop_id, status, created_at desc);

alter table public.shop_invitations enable row level security;

drop policy if exists shop_invitations_read_owner_manager
on public.shop_invitations;
create policy shop_invitations_read_owner_manager
on public.shop_invitations
for select
using (public.is_shop_owner_or_manager(barber_shop_id));

drop policy if exists shop_invitations_manage_owner_manager
on public.shop_invitations;
create policy shop_invitations_manage_owner_manager
on public.shop_invitations
for all
using (public.is_shop_owner_or_manager(barber_shop_id))
with check (public.is_shop_owner_or_manager(barber_shop_id));

create or replace function public.create_shop_invitation(
  p_barber_shop_id uuid,
  p_email text,
  p_name text,
  p_role public.shop_member_role default 'barber',
  p_bio text default null,
  p_photo_url text default null,
  p_starting_price numeric default 0,
  p_commission_percent numeric default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_email text := lower(trim(coalesce(p_email, '')));
  normalized_name text := trim(coalesce(p_name, ''));
  raw_token text := encode(gen_random_bytes(24), 'hex');
  invitation_id uuid;
  professional_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Faça login para convidar um profissional.';
  end if;

  if not public.is_shop_owner_or_manager(p_barber_shop_id) then
    raise exception 'Somente o dono ou gerente pode convidar profissionais.';
  end if;

  if normalized_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Informe um e-mail válido.';
  end if;

  if length(normalized_name) < 2 then
    raise exception 'Informe o nome do profissional.';
  end if;

  if p_role = 'owner' then
    raise exception 'O papel de proprietário não pode ser concedido por convite.';
  end if;

  if p_commission_percent < 0 or p_commission_percent > 100 then
    raise exception 'A comissão deve estar entre 0 e 100.';
  end if;

  if exists (
    select 1
    from public.shop_members member
    join public.users account on account.id = member.user_id
    where member.barber_shop_id = p_barber_shop_id
      and lower(account.email) = normalized_email
      and member.is_active = true
  ) then
    raise exception 'Este usuário já faz parte da equipe.';
  end if;

  select barber_id
  into professional_id
  from public.shop_invitations
  where barber_shop_id = p_barber_shop_id
    and lower(email) = normalized_email
    and status = 'pending'
  order by created_at desc
  limit 1;

  update public.shop_invitations
  set
    status = 'revoked',
    updated_at = now()
  where barber_shop_id = p_barber_shop_id
    and lower(email) = normalized_email
    and status = 'pending';

  if p_role = 'barber' and professional_id is null then
    select id
    into professional_id
    from public.barbers
    where barber_shop_id = p_barber_shop_id
      and lower(name) = lower(normalized_name)
      and user_id is null
    limit 1;
  end if;

  if p_role = 'barber' and professional_id is not null then
    update public.barbers
    set
      name = normalized_name,
      bio = nullif(trim(coalesce(p_bio, '')), ''),
      photo_url = nullif(trim(coalesce(p_photo_url, '')), ''),
      starting_price = greatest(coalesce(p_starting_price, 0), 0),
      commission_percent = coalesce(p_commission_percent, 0),
      is_active = false,
      updated_at = now()
    where id = professional_id
      and barber_shop_id = p_barber_shop_id;
  elsif p_role = 'barber' then
    insert into public.barbers (
      barber_shop_id,
      name,
      bio,
      photo_url,
      starting_price,
      commission_percent,
      is_active
    )
    values (
      p_barber_shop_id,
      normalized_name,
      nullif(trim(coalesce(p_bio, '')), ''),
      nullif(trim(coalesce(p_photo_url, '')), ''),
      greatest(coalesce(p_starting_price, 0), 0),
      coalesce(p_commission_percent, 0),
      false
    )
    returning id into professional_id;
  end if;

  insert into public.shop_invitations (
    barber_shop_id,
    barber_id,
    email,
    role,
    token_hash,
    invited_by
  )
  values (
    p_barber_shop_id,
    professional_id,
    normalized_email,
    p_role,
    encode(digest(raw_token, 'sha256'), 'hex'),
    auth.uid()
  )
  returning id into invitation_id;

  return jsonb_build_object(
    'invitation_id', invitation_id,
    'barber_id', professional_id,
    'email', normalized_email,
    'role', p_role,
    'token', raw_token,
    'expires_at', now() + interval '7 days'
  );
end;
$$;

create or replace function public.accept_shop_invitation(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
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

  select *
  into invitation
  from public.shop_invitations
  where token_hash = encode(digest(trim(coalesce(p_token, '')), 'sha256'), 'hex')
  for update;

  if invitation.id is null then
    raise exception 'Convite inválido.';
  end if;

  if invitation.status = 'accepted' and invitation.accepted_by = auth.uid() then
    return jsonb_build_object(
      'barber_shop_id', invitation.barber_shop_id,
      'role', invitation.role,
      'already_accepted', true
    );
  end if;

  if invitation.status <> 'pending' then
    raise exception 'Este convite não está mais disponível.';
  end if;

  if invitation.expires_at <= now() then
    update public.shop_invitations
    set status = 'expired', updated_at = now()
    where id = invitation.id;
    raise exception 'Este convite expirou. Solicite um novo convite.';
  end if;

  if current_email is null or current_email <> lower(invitation.email) then
    raise exception 'Entre com o mesmo e-mail que recebeu o convite.';
  end if;

  insert into public.shop_members (
    barber_shop_id,
    user_id,
    role,
    is_active,
    invited_by
  )
  values (
    invitation.barber_shop_id,
    auth.uid(),
    invitation.role,
    true,
    invitation.invited_by
  )
  on conflict (barber_shop_id, user_id) do update
  set
    role = excluded.role,
    is_active = true,
    invited_by = excluded.invited_by,
    updated_at = now();

  if invitation.role = 'barber' and invitation.barber_id is not null then
    update public.barbers
    set
      user_id = auth.uid(),
      is_active = true,
      updated_at = now()
    where id = invitation.barber_id
      and barber_shop_id = invitation.barber_shop_id;
  end if;

  update public.shop_invitations
  set
    status = 'accepted',
    accepted_at = now(),
    accepted_by = auth.uid(),
    updated_at = now()
  where id = invitation.id;

  return jsonb_build_object(
    'barber_shop_id', invitation.barber_shop_id,
    'barber_id', invitation.barber_id,
    'role', invitation.role,
    'already_accepted', false
  );
end;
$$;

create or replace function public.revoke_shop_invitation(p_invitation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  invitation public.shop_invitations%rowtype;
begin
  select *
  into invitation
  from public.shop_invitations
  where id = p_invitation_id
  for update;

  if invitation.id is null then
    raise exception 'Convite não encontrado.';
  end if;

  if not public.is_shop_owner_or_manager(invitation.barber_shop_id) then
    raise exception 'Você não pode revogar este convite.';
  end if;

  update public.shop_invitations
  set status = 'revoked', updated_at = now()
  where id = invitation.id and status = 'pending';

  if invitation.barber_id is not null
    and not exists (
      select 1
      from public.shop_invitations accepted
      where accepted.barber_id = invitation.barber_id
        and accepted.status = 'accepted'
    ) then
    delete from public.barbers where id = invitation.barber_id;
  end if;
end;
$$;

revoke all on function public.create_shop_invitation(
  uuid, text, text, public.shop_member_role, text, text, numeric, numeric
) from public;
grant execute on function public.create_shop_invitation(
  uuid, text, text, public.shop_member_role, text, text, numeric, numeric
) to authenticated;

revoke all on function public.accept_shop_invitation(text) from public;
grant execute on function public.accept_shop_invitation(text) to authenticated;

revoke all on function public.revoke_shop_invitation(uuid) from public;
grant execute on function public.revoke_shop_invitation(uuid) to authenticated;
