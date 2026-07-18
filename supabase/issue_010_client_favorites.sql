-- ISSUE-010 - Favoritos privados do cliente
-- Execute no SQL Editor do Supabase antes de testar a UI-012.

create table if not exists public.client_favorites (
  client_id uuid not null references public.users(id) on delete cascade,
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (client_id, barber_shop_id)
);

alter table public.client_favorites enable row level security;

grant select, insert, delete on public.client_favorites to authenticated;

drop policy if exists client_favorites_read_own on public.client_favorites;
create policy client_favorites_read_own on public.client_favorites
for select to authenticated
using (auth.uid() = client_id);

drop policy if exists client_favorites_insert_own on public.client_favorites;
create policy client_favorites_insert_own on public.client_favorites
for insert to authenticated
with check (
  auth.uid() = client_id
  and exists (
    select 1 from public.barber_shops shop
    where shop.id = barber_shop_id and shop.is_active = true
  )
);

drop policy if exists client_favorites_delete_own on public.client_favorites;
create policy client_favorites_delete_own on public.client_favorites
for delete to authenticated
using (auth.uid() = client_id);
