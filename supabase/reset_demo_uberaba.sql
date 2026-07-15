-- CLUBE DA REGUA - RESET COMPLETO DA BASE DE TESTE EM UBERABA/MG
-- ATENCAO: remove todas as barbearias e todos os dados dependentes.

begin;

-- 1. Garante suporte a coordenadas reais.
alter table public.barber_shops
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

alter table public.barber_shops
  drop constraint if exists barber_shops_latitude_range,
  add constraint barber_shops_latitude_range
    check (latitude is null or latitude between -90 and 90),
  drop constraint if exists barber_shops_longitude_range,
  add constraint barber_shops_longitude_range
    check (longitude is null or longitude between -180 and 180);

-- 2. Limpa barbearias e todas as tabelas dependentes.
truncate table public.barber_shops cascade;

-- 3. Recria categorias publicas.
insert into public.service_categories (name, icon, sort_order, is_active)
values
  ('Corte', 'content_cut', 1, true),
  ('Barba', 'face', 2, true),
  ('Combo', 'auto_awesome', 3, true),
  ('Infantil', 'child_care', 4, true),
  ('Premium', 'workspace_premium', 5, true);

-- 4. Barbearias ficticias em Uberaba.
-- A ultima unidade fica propositalmente fora do raio de 10 km.
insert into public.barber_shops (
  id, name, slug, description, phone, whatsapp, address, city, state,
  latitude, longitude, cover_url, opening_time, closing_time, is_active
)
values
  (
    'a1000000-0000-4000-8000-000000000001',
    'Régua Urbana Centro',
    'regua-urbana-centro',
    'Barbearia urbana premium especializada em cortes modernos e barba.',
    '(34) 3333-1001', '553499991001',
    'Praça Rui Barbosa, Centro', 'Uberaba', 'MG',
    -19.747230, -47.939180,
    'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=1200&q=85',
    '08:30', '20:00', true
  ),
  (
    'a1000000-0000-4000-8000-000000000002',
    'Barbearia Spartan Abadia',
    'barbearia-spartan-abadia',
    'Cortes de precisão, barba espartana e atendimento premium.',
    '(34) 3333-1002', '553499991002',
    'Avenida Prudente de Morais, Abadia', 'Uberaba', 'MG',
    -19.757090, -47.932520,
    'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=1200&q=85',
    '09:00', '21:00', true
  ),
  (
    'a1000000-0000-4000-8000-000000000003',
    'Clube 34 Mercês',
    'clube-34-merces',
    'Experiência clássica com estética contemporânea.',
    '(34) 3333-1003', '553499991003',
    'Avenida Santos Dumont, Mercês', 'Uberaba', 'MG',
    -19.738760, -47.947450,
    'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=1200&q=85',
    '08:00', '19:30', true
  ),
  (
    'a1000000-0000-4000-8000-000000000004',
    'Mestre da Régua São Benedito',
    'mestre-da-regua-sao-benedito',
    'Visagismo masculino, acabamento e cuidado com a barba.',
    '(34) 3333-1004', '553499991004',
    'Avenida Leopoldino de Oliveira, São Benedito', 'Uberaba', 'MG',
    -19.752870, -47.949950,
    'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=1200&q=85',
    '09:00', '20:00', true
  ),
  (
    'a1000000-0000-4000-8000-000000000005',
    'Dom Barber Santa Maria',
    'dom-barber-santa-maria',
    'Ambiente sofisticado para corte, barba e tratamentos premium.',
    '(34) 3333-1005', '553499991005',
    'Avenida Santa Beatriz, Santa Maria', 'Uberaba', 'MG',
    -19.767170, -47.953550,
    'https://images.unsplash.com/photo-1521490683712-35a1cb235d1c?auto=format&fit=crop&w=1200&q=85',
    '09:00', '21:00', true
  ),
  (
    'a1000000-0000-4000-8000-000000000006',
    'Black Crown Olinda',
    'black-crown-olinda',
    'Barbearia jovem com música, estilo urbano e atendimento rápido.',
    '(34) 3333-1006', '553499991006',
    'Avenida Niza Marquez Guaritá, Olinda', 'Uberaba', 'MG',
    -19.728990, -47.919740,
    'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?auto=format&fit=crop&w=1200&q=85',
    '10:00', '22:00', true
  ),
  (
    'a1000000-0000-4000-8000-000000000007',
    'The Barber Boa Vista',
    'the-barber-boa-vista',
    'Tradição de barbearia com técnicas atuais e produtos selecionados.',
    '(34) 3333-1007', '553499991007',
    'Avenida Elias Cruvinel, Boa Vista', 'Uberaba', 'MG',
    -19.719100, -47.944630,
    'https://images.unsplash.com/photo-1593702295094-aea22597af65?auto=format&fit=crop&w=1200&q=85',
    '08:30', '19:00', true
  ),
  (
    'a1000000-0000-4000-8000-000000000008',
    'Régua Prime Univerdecidade',
    'regua-prime-univerdecidade',
    'Conceito premium para quem busca estilo, conforto e pontualidade.',
    '(34) 3333-1008', '553499991008',
    'Avenida Randolfo Borges Júnior, Univerdecidade', 'Uberaba', 'MG',
    -19.735290, -47.978180,
    'https://images.unsplash.com/photo-1512690459411-b9245aed614b?auto=format&fit=crop&w=1200&q=85',
    '09:00', '20:30', true
  ),
  (
    'a1000000-0000-4000-8000-000000000009',
    'Unidade Fora do Raio',
    'unidade-fora-do-raio',
    'Unidade de controle criada para validar o limite geográfico.',
    '(34) 3333-1099', '553499991099',
    'Zona Rural de Uberaba', 'Uberaba', 'MG',
    -19.873000, -48.080000,
    'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?auto=format&fit=crop&w=1200&q=85',
    '09:00', '18:00', true
  );

-- 5. Configuracoes das unidades.
insert into public.shop_settings (
  barber_shop_id, booking_interval_minutes, min_cancel_hours,
  auto_confirm_appointments, require_payment_to_confirm, loyalty_enabled,
  pix_key, settings
)
select
  id, 30, 2, true, false, true,
  'demo-' || slug || '@clubedaregua.test',
  jsonb_build_object(
    'instagram', '@' || replace(slug, '-', ''),
    'secondary_color', '#F3B200',
    'booking_days_ahead', 30,
    'min_notice_minutes', 60
  )
from public.barber_shops;

-- 6. Dois profissionais por unidade.
insert into public.barbers (
  barber_shop_id, name, bio, photo_url, rating, starting_price,
  commission_percent, is_active
)
select
  shop.id,
  professional.name,
  professional.bio,
  professional.photo_url,
  professional.rating,
  professional.starting_price,
  40,
  true
from public.barber_shops shop
cross join (
  values
    (
      'Rafael Martins',
      'Especialista em degradê, freestyle e acabamento de precisão.',
      'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=700&q=85',
      4.9::numeric,
      45.00::numeric
    ),
    (
      'Lucas Andrade',
      'Especialista em barba, visagismo e cortes clássicos.',
      'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?auto=format&fit=crop&w=700&q=85',
      4.7::numeric,
      40.00::numeric
    )
) as professional(name, bio, photo_url, rating, starting_price);

-- 7. Servicos de cada unidade.
insert into public.services (
  barber_shop_id, category_id, name, description,
  duration_minutes, price, image_url, is_active
)
select
  shop.id,
  category.id,
  service.name,
  service.description,
  service.duration_minutes,
  service.price,
  service.image_url,
  true
from public.barber_shops shop
cross join (
  values
    (
      'Corte', 'Corte premium', 'Corte com lavagem e acabamento.',
      45, 45.00::numeric,
      'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=700&q=85'
    ),
    (
      'Barba', 'Barba completa', 'Toalha quente, desenho e finalização.',
      35, 35.00::numeric,
      'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=700&q=85'
    ),
    (
      'Combo', 'Corte + barba', 'Experiência completa de cabelo e barba.',
      75, 75.00::numeric,
      'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=700&q=85'
    )
) as service(category_name, name, description, duration_minutes, price, image_url)
join public.service_categories category
  on category.barber_shop_id is null
 and category.name = service.category_name;

-- 8. Todos os profissionais atendem todos os servicos da propria unidade.
insert into public.barber_services (
  barber_shop_id, barber_id, service_id, is_active
)
select
  barber.barber_shop_id,
  barber.id,
  service.id,
  true
from public.barbers barber
join public.services service
  on service.barber_shop_id = barber.barber_shop_id;

-- 9. Agenda de segunda a sabado.
insert into public.schedules (
  barber_shop_id, barber_id, weekday, start_time, end_time,
  slot_minutes, is_active
)
select
  barber.barber_shop_id,
  barber.id,
  weekday.day,
  '09:00'::time,
  case when weekday.day = 6 then '16:00'::time else '20:00'::time end,
  30,
  true
from public.barbers barber
cross join (values (1), (2), (3), (4), (5), (6)) as weekday(day);

commit;

-- Resultado para conferencia.
select
  name,
  address,
  latitude,
  longitude,
  case
    when name = 'Unidade Fora do Raio' then 'CONTROLE: deve ser excluida'
    else 'UBERABA: candidata ao raio de 10 km'
  end as resultado_esperado
from public.barber_shops
order by name;
