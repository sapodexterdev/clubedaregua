-- Clube da Regua - storage de logos da barbearia
-- Execute no Supabase para preparar upload/publicacao de logos.

insert into storage.buckets (id, name, public)
values ('shop-logos', 'shop-logos', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists shop_logos_read_public on storage.objects;
create policy shop_logos_read_public on storage.objects
for select using (bucket_id = 'shop-logos');

drop policy if exists shop_logos_insert_staff on storage.objects;
create policy shop_logos_insert_staff on storage.objects
for insert with check (
  bucket_id = 'shop-logos'
  and public.is_shop_member((storage.foldername(name))[1]::uuid)
);

drop policy if exists shop_logos_update_staff on storage.objects;
create policy shop_logos_update_staff on storage.objects
for update using (
  bucket_id = 'shop-logos'
  and public.is_shop_member((storage.foldername(name))[1]::uuid)
)
with check (
  bucket_id = 'shop-logos'
  and public.is_shop_member((storage.foldername(name))[1]::uuid)
);
