-- Coordenadas reais para descoberta de barbearias por proximidade.
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

comment on column public.barber_shops.latitude is
  'Latitude WGS84 do endereço confirmado da barbearia.';
comment on column public.barber_shops.longitude is
  'Longitude WGS84 do endereço confirmado da barbearia.';
