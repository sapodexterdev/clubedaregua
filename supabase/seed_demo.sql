do $$
begin
  if to_regclass('public.barber_shops') is null then
    raise exception 'Rode primeiro o arquivo supabase/schema.sql completo. A tabela public.barber_shops ainda nao existe.';
  end if;
end $$;

with demo_shop as (
  insert into public.barber_shops (
    name,
    slug,
    description,
    city,
    state,
    cover_url,
    opening_time,
    closing_time
  )
  values (
    'Barbearia Elite',
    'barbearia-elite-demo',
    'Barbearia premium para cortes, barba e combos.',
    'Sao Paulo',
    'SP',
    'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=1200&q=80',
    '09:00',
    '20:00'
  )
  on conflict (slug) do update set
    name = excluded.name,
    description = excluded.description,
    cover_url = excluded.cover_url
  returning id
),
demo_categories as (
  select id, name
  from public.service_categories
  where barber_shop_id is null
),
demo_services as (
  insert into public.services (
    barber_shop_id,
    category_id,
    name,
    description,
    duration_minutes,
    price,
    image_url
  )
  select
    demo_shop.id,
    demo_categories.id,
    case demo_categories.name
      when 'Cabelo' then 'Corte masculino'
      when 'Barba' then 'Barba completa'
      when 'Combo' then 'Corte + barba'
      else 'Sobrancelha'
    end,
    case demo_categories.name
      when 'Cabelo' then 'Corte moderno com acabamento premium.'
      when 'Barba' then 'Toalha quente, desenho e finalizacao.'
      when 'Combo' then 'Experiencia completa de corte e barba.'
      else 'Design rapido para acabamento do visual.'
    end,
    case demo_categories.name
      when 'Combo' then 60
      else 30
    end,
    case demo_categories.name
      when 'Cabelo' then 49.90
      when 'Barba' then 35.00
      when 'Combo' then 79.90
      else 25.00
    end,
    'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=900&q=80'
  from demo_shop
  join demo_categories on true
  where not exists (
    select 1
    from public.services s
    where s.barber_shop_id = demo_shop.id
      and s.name = case demo_categories.name
        when 'Cabelo' then 'Corte masculino'
        when 'Barba' then 'Barba completa'
        when 'Combo' then 'Corte + barba'
        else 'Sobrancelha'
      end
  )
  returning id, barber_shop_id
),
demo_barbers as (
  insert into public.barbers (
    barber_shop_id,
    name,
    bio,
    photo_url,
    rating,
    starting_price,
    commission_percent
  )
  select
    demo_shop.id,
    barber.name,
    barber.bio,
    barber.photo_url,
    barber.rating,
    barber.starting_price,
    40
  from demo_shop
  cross join (
    values
      (
        'Davi Marcomin',
        'Especialista em cortes modernos e acabamento de barba.',
        'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=900&q=80',
        4.9,
        49.90
      ),
      (
        'Ricardo Anderson',
        'Barbeiro premium focado em visagismo, barba e combos rapidos.',
        'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?auto=format&fit=crop&w=900&q=80',
        4.7,
        35.00
      )
  ) as barber(name, bio, photo_url, rating, starting_price)
  where not exists (
    select 1
    from public.barbers b
    where b.barber_shop_id = demo_shop.id
      and b.name = barber.name
  )
  returning id, barber_shop_id
)
insert into public.barber_services (barber_shop_id, barber_id, service_id)
select b.barber_shop_id, b.id, s.id
from (
  select id, barber_shop_id from demo_barbers
  union
  select b.id, b.barber_shop_id
  from public.barbers b
  join demo_shop ds on ds.id = b.barber_shop_id
  where b.name in ('Davi Marcomin', 'Ricardo Anderson')
) b
join public.services s on s.barber_shop_id = b.barber_shop_id
on conflict (barber_id, service_id) do nothing;
