-- Clube da Regua - vincular usuario da equipe a barbearia demo
-- 1. Crie o usuario em Authentication > Users no Supabase.
-- 2. Troque o email abaixo pelo email criado.
-- 3. Execute este SQL.

insert into public.shop_members (
  barber_shop_id,
  user_id,
  role,
  is_active
)
select
  '11111111-1111-4111-8111-111111111111',
  users.id,
  'owner',
  true
from public.users
where users.email = 'sapodexter@gmail.com'
on conflict (barber_shop_id, user_id) do update set
  role = excluded.role,
  is_active = true,
  updated_at = now();
