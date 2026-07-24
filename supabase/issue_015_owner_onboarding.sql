-- ISSUE-015 - onboarding seguro de uma nova barbearia
-- Cria, em uma unica transacao:
-- barbearia, configuracoes, vinculo do dono, trial e perfil de barbeiro opcional.

create or replace function public.create_owner_barbershop(
  p_name text,
  p_phone text,
  p_whatsapp text,
  p_address text,
  p_city text,
  p_state text,
  p_owner_name text,
  p_serves_as_barber boolean default false,
  p_plan_slug text default 'pro'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_shop_id uuid := gen_random_uuid();
  selected_plan_id uuid;
  normalized_name text;
  generated_slug text;
begin
  if current_user_id is null then
    raise exception 'Faça login para cadastrar sua barbearia.';
  end if;

  if not exists (
    select 1
    from public.users
    where id = current_user_id
      and is_active = true
  ) then
    raise exception 'Conta inválida ou inativa.';
  end if;

  normalized_name := nullif(trim(p_name), '');
  if normalized_name is null or char_length(normalized_name) < 3 then
    raise exception 'Informe o nome da barbearia.';
  end if;

  if nullif(trim(p_city), '') is null or
     nullif(trim(p_state), '') is null then
    raise exception 'Informe a cidade e o estado.';
  end if;

  if exists (
    select 1
    from public.barber_shops
    where owner_id = current_user_id
      and is_active = true
  ) then
    raise exception 'Esta conta já possui uma barbearia ativa.';
  end if;

  if exists (
    select 1
    from public.shop_members
    where user_id = current_user_id
      and is_active = true
  ) or exists (
    select 1
    from public.barbers
    where user_id = current_user_id
      and is_active = true
  ) then
    raise exception 'Esta conta já está vinculada a uma barbearia. O MVP permite uma unidade profissional por conta.';
  end if;

  select id
    into selected_plan_id
  from public.plans
  where slug = coalesce(nullif(trim(p_plan_slug), ''), 'pro')
    and is_active = true
  limit 1;

  if selected_plan_id is null then
    raise exception 'Plano indisponível para o período de teste.';
  end if;

  generated_slug := lower(
    regexp_replace(
      translate(
        normalized_name,
        'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
        'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'
      ),
      '[^a-zA-Z0-9]+',
      '-',
      'g'
    )
  );
  generated_slug := trim(both '-' from generated_slug);
  if generated_slug = '' then
    generated_slug := 'barbearia';
  end if;
  generated_slug := generated_slug || '-' ||
    substring(replace(new_shop_id::text, '-', '') from 1 for 8);

  insert into public.barber_shops (
    id,
    owner_id,
    name,
    slug,
    phone,
    whatsapp,
    address,
    city,
    state,
    is_active
  )
  values (
    new_shop_id,
    current_user_id,
    normalized_name,
    generated_slug,
    nullif(trim(p_phone), ''),
    nullif(trim(p_whatsapp), ''),
    nullif(trim(p_address), ''),
    trim(p_city),
    upper(trim(p_state)),
    true
  );

  insert into public.shop_settings (barber_shop_id)
  values (new_shop_id);

  insert into public.shop_members (
    barber_shop_id,
    user_id,
    role,
    is_active
  )
  values (
    new_shop_id,
    current_user_id,
    'owner',
    true
  );

  insert into public.subscriptions (
    barber_shop_id,
    plan_id,
    status,
    trial_ends_at,
    current_period_starts_at,
    current_period_ends_at
  )
  values (
    new_shop_id,
    selected_plan_id,
    'trialing',
    now() + interval '14 days',
    now(),
    now() + interval '14 days'
  );

  if coalesce(p_serves_as_barber, false) then
    insert into public.barbers (
      barber_shop_id,
      user_id,
      name,
      starting_price,
      commission_percent,
      is_active
    )
    values (
      new_shop_id,
      current_user_id,
      coalesce(nullif(trim(p_owner_name), ''), normalized_name),
      0,
      100,
      true
    );
  end if;

  return jsonb_build_object(
    'barber_shop_id', new_shop_id,
    'slug', generated_slug,
    'trial_ends_at', now() + interval '14 days',
    'serves_as_barber', coalesce(p_serves_as_barber, false)
  );
end;
$$;

revoke all on function public.create_owner_barbershop(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean,
  text
) from public;

grant execute on function public.create_owner_barbershop(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean,
  text
) to authenticated;

comment on function public.create_owner_barbershop(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean,
  text
) is 'Cria uma barbearia com dono, configuracao inicial e trial de 14 dias.';
