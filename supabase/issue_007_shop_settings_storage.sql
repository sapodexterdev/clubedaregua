-- Clube da Regua - identidade da barbearia
-- Execute no Supabase para preparar upload/publicacao de logo, banner
-- e leitura publica das configuracoes usadas pelo app Cliente.

insert into storage.buckets (id, name, public)
values ('shop-media', 'shop-media', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists shop_media_read_public on storage.objects;
create policy shop_media_read_public on storage.objects
for select using (bucket_id = 'shop-media');

drop policy if exists shop_media_insert_staff on storage.objects;
create policy shop_media_insert_staff on storage.objects
for insert with check (
  bucket_id = 'shop-media'
  and public.is_shop_member((storage.foldername(name))[1]::uuid)
);

drop policy if exists shop_media_update_staff on storage.objects;
create policy shop_media_update_staff on storage.objects
for update using (
  bucket_id = 'shop-media'
  and public.is_shop_member((storage.foldername(name))[1]::uuid)
)
with check (
  bucket_id = 'shop-media'
  and public.is_shop_member((storage.foldername(name))[1]::uuid)
);

drop policy if exists shop_settings_read_public_active_shop on public.shop_settings;
create policy shop_settings_read_public_active_shop on public.shop_settings
for select using (
  exists (
    select 1
    from public.barber_shops shop
    where shop.id = shop_settings.barber_shop_id
      and shop.is_active = true
  )
);
