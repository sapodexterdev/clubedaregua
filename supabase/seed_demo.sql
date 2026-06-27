-- Clube da Regua - demo seed
-- Execute somente depois de supabase/schema.sql.
-- Pode ser executado mais de uma vez.

do $$
begin
  if to_regclass('public.barber_shops') is null then
    raise exception 'Rode primeiro supabase/schema.sql. A tabela public.barber_shops ainda nao existe.';
  end if;
end $$;

insert into public.barber_shops (
  id,
  name,
  slug,
  description,
  phone,
  whatsapp,
  address,
  city,
  state,
  cover_url,
  opening_time,
  closing_time
)
values (
  '11111111-1111-4111-8111-111111111111',
  'Barbearia Elite',
  'barbearia-elite-demo',
  'Barbearia premium para cortes, barba e combos.',
  '(11) 99999-0000',
  '5511999990000',
  'Rua Demo, 123',
  'Sao Paulo',
  'SP',
  'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=1200&q=80',
  '09:00',
  '20:00'
)
on conflict (id) do update set
  name = excluded.name,
  slug = excluded.slug,
  description = excluded.description,
  phone = excluded.phone,
  whatsapp = excluded.whatsapp,
  cover_url = excluded.cover_url,
  opening_time = excluded.opening_time,
  closing_time = excluded.closing_time;

insert into public.shop_settings (
  barber_shop_id,
  booking_interval_minutes,
  min_cancel_hours,
  auto_confirm_appointments,
  require_payment_to_confirm,
  loyalty_enabled,
  pix_key
)
values (
  '11111111-1111-4111-8111-111111111111',
  30,
  2,
  false,
  false,
  true,
  'pix-demo@clubedaregua.com'
)
on conflict (barber_shop_id) do update set
  booking_interval_minutes = excluded.booking_interval_minutes,
  min_cancel_hours = excluded.min_cancel_hours,
  auto_confirm_appointments = excluded.auto_confirm_appointments,
  require_payment_to_confirm = excluded.require_payment_to_confirm,
  loyalty_enabled = excluded.loyalty_enabled,
  pix_key = excluded.pix_key;

insert into public.subscriptions (id, barber_shop_id, plan_id, status, trial_ends_at)
select
  '22222222-2222-4222-8222-222222222222',
  '11111111-1111-4111-8111-111111111111',
  plans.id,
  'trialing',
  now() + interval '14 days'
from public.plans
where plans.slug = 'pro'
on conflict (id) do update set
  plan_id = excluded.plan_id,
  status = excluded.status,
  trial_ends_at = excluded.trial_ends_at;

insert into public.barbers (
  id,
  barber_shop_id,
  name,
  bio,
  photo_url,
  rating,
  starting_price,
  commission_percent
)
values
  (
    '33333333-3333-4333-8333-333333333331',
    '11111111-1111-4111-8111-111111111111',
    'Davi Marcomin',
    'Especialista em cortes modernos e acabamento de barba.',
    'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=900&q=80',
    4.9,
    55.00,
    40.00
  ),
  (
    '33333333-3333-4333-8333-333333333332',
    '11111111-1111-4111-8111-111111111111',
    'Ricardo Anderson',
    'Barbeiro premium focado em visagismo, barba e combos rapidos.',
    'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?auto=format&fit=crop&w=900&q=80',
    4.7,
    40.00,
    35.00
  )
on conflict (id) do update set
  name = excluded.name,
  bio = excluded.bio,
  photo_url = excluded.photo_url,
  rating = excluded.rating,
  starting_price = excluded.starting_price,
  commission_percent = excluded.commission_percent,
  is_active = true;

insert into public.services (
  id,
  barber_shop_id,
  category_id,
  name,
  description,
  duration_minutes,
  price,
  image_url
)
select
  service.id,
  '11111111-1111-4111-8111-111111111111',
  categories.id,
  service.name,
  service.description,
  service.duration_minutes,
  service.price,
  service.image_url
from (
  values
    (
      '44444444-4444-4444-8444-444444444441'::uuid,
      'Cabelo',
      'Corte premium',
      'Corte moderno com acabamento premium.',
      45,
      55.00,
      'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=900&q=80'
    ),
    (
      '44444444-4444-4444-8444-444444444442'::uuid,
      'Barba',
      'Barba completa',
      'Toalha quente, desenho e finalizacao.',
      35,
      40.00,
      'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=900&q=80'
    ),
    (
      '44444444-4444-4444-8444-444444444443'::uuid,
      'Combo',
      'Corte + barba',
      'Experiencia completa de corte e barba.',
      70,
      85.00,
      'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=900&q=80'
    )
) as service(id, category_name, name, description, duration_minutes, price, image_url)
left join public.service_categories categories
  on categories.barber_shop_id is null
 and lower(categories.name) = lower(service.category_name)
on conflict (id) do update set
  category_id = excluded.category_id,
  name = excluded.name,
  description = excluded.description,
  duration_minutes = excluded.duration_minutes,
  price = excluded.price,
  image_url = excluded.image_url,
  is_active = true;

insert into public.barber_services (barber_shop_id, barber_id, service_id)
select
  '11111111-1111-4111-8111-111111111111',
  barber.id,
  service.id
from public.barbers barber
cross join public.services service
where barber.barber_shop_id = '11111111-1111-4111-8111-111111111111'
  and service.barber_shop_id = '11111111-1111-4111-8111-111111111111'
on conflict (barber_id, service_id) do update set is_active = true;

insert into public.schedules (
  barber_shop_id,
  barber_id,
  weekday,
  start_time,
  end_time,
  slot_minutes
)
select
  '11111111-1111-4111-8111-111111111111',
  barber.id,
  weekday.day,
  '09:00',
  case when weekday.day = 6 then '14:00'::time else '18:00'::time end,
  30
from public.barbers barber
cross join (values (1), (2), (3), (4), (5), (6)) as weekday(day)
where barber.barber_shop_id = '11111111-1111-4111-8111-111111111111'
on conflict (barber_id, weekday, start_time) do update set
  end_time = excluded.end_time,
  slot_minutes = excluded.slot_minutes,
  is_active = true;

insert into public.appointments (
  id,
  barber_shop_id,
  barber_id,
  service_id,
  starts_at,
  ends_at,
  status,
  total_price,
  notes
)
values
  (
    '55555555-5555-4555-8555-555555555551',
    '11111111-1111-4111-8111-111111111111',
    '33333333-3333-4333-8333-333333333331',
    '44444444-4444-4444-8444-444444444443',
    date_trunc('day', now()) + interval '9 hours',
    date_trunc('day', now()) + interval '10 hours 10 minutes',
    'confirmed',
    85.00,
    'Cliente prefere acabamento baixo.'
  ),
  (
    '55555555-5555-4555-8555-555555555552',
    '11111111-1111-4111-8111-111111111111',
    '33333333-3333-4333-8333-333333333332',
    '44444444-4444-4444-8444-444444444441',
    date_trunc('day', now()) + interval '10 hours 30 minutes',
    date_trunc('day', now()) + interval '11 hours 15 minutes',
    'pending',
    55.00,
    'Agendamento demo pendente.'
  )
on conflict (id) do update set
  starts_at = excluded.starts_at,
  ends_at = excluded.ends_at,
  status = excluded.status,
  total_price = excluded.total_price,
  notes = excluded.notes;

insert into public.payments (
  id,
  barber_shop_id,
  appointment_id,
  method,
  status,
  amount,
  pix_qr_code
)
values
  (
    '66666666-6666-4666-8666-666666666661',
    '11111111-1111-4111-8111-111111111111',
    '55555555-5555-4555-8555-555555555551',
    'pix',
    'paid',
    85.00,
    'pix-demo-paid'
  ),
  (
    '66666666-6666-4666-8666-666666666662',
    '11111111-1111-4111-8111-111111111111',
    '55555555-5555-4555-8555-555555555552',
    'pix',
    'pending',
    55.00,
    'pix-demo-pending'
  )
on conflict (id) do update set
  status = excluded.status,
  amount = excluded.amount,
  pix_qr_code = excluded.pix_qr_code;

insert into public.coupons (
  id,
  barber_shop_id,
  code,
  description,
  discount_percent,
  max_uses,
  starts_at,
  ends_at
)
values (
  '77777777-7777-4777-8777-777777777771',
  '11111111-1111-4111-8111-111111111111',
  'CORTE20',
  '20% OFF no proximo corte',
  20,
  100,
  now(),
  now() + interval '30 days'
)
on conflict (id) do update set
  code = excluded.code,
  description = excluded.description,
  discount_percent = excluded.discount_percent,
  max_uses = excluded.max_uses,
  starts_at = excluded.starts_at,
  ends_at = excluded.ends_at,
  is_active = true;

insert into public.stock_items (
  id,
  barber_shop_id,
  name,
  sku,
  quantity,
  min_quantity,
  unit_cost
)
values
  (
    '88888888-8888-4888-8888-888888888881',
    '11111111-1111-4111-8111-111111111111',
    'Pomada modeladora',
    'POM-001',
    3,
    8,
    22.00
  ),
  (
    '88888888-8888-4888-8888-888888888882',
    '11111111-1111-4111-8111-111111111111',
    'Lamina descartavel',
    'LAM-001',
    18,
    30,
    1.50
  )
on conflict (id) do update set
  quantity = excluded.quantity,
  min_quantity = excluded.min_quantity,
  unit_cost = excluded.unit_cost;

insert into public.cash_movements (
  id,
  barber_shop_id,
  appointment_id,
  type,
  amount,
  description,
  movement_date
)
values
  (
    '99999999-9999-4999-8999-999999999991',
    '11111111-1111-4111-8111-111111111111',
    '55555555-5555-4555-8555-555555555551',
    'income',
    85.00,
    'PIX - Corte + barba',
    current_date
  ),
  (
    '99999999-9999-4999-8999-999999999992',
    '11111111-1111-4111-8111-111111111111',
    null,
    'expense',
    180.00,
    'Compra de pomada',
    current_date
  )
on conflict (id) do update set
  amount = excluded.amount,
  description = excluded.description,
  movement_date = excluded.movement_date;
