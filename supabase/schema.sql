create extension if not exists "pgcrypto";

create type public.user_role as enum ('client', 'barber', 'manager', 'owner', 'admin');
create type public.shop_member_role as enum ('owner', 'manager', 'barber', 'receptionist');
create type public.subscription_status as enum ('trialing', 'active', 'past_due', 'cancelled', 'expired');
create type public.appointment_status as enum ('pending', 'confirmed', 'completed', 'cancelled', 'no_show');
create type public.payment_status as enum ('pending', 'paid', 'failed', 'refunded');
create type public.payment_method as enum ('pix', 'cash', 'card');
create type public.cash_movement_type as enum ('income', 'expense');

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  role public.user_role not null default 'client',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  full_name text not null,
  phone text,
  avatar_url text,
  birth_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.plans (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  monthly_price numeric(10,2) not null default 0,
  max_barbers integer not null default 1,
  max_shops integer not null default 1,
  features jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.barber_shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.users(id) on delete set null,
  name text not null,
  slug text not null unique,
  description text,
  document text,
  phone text,
  whatsapp text,
  address text,
  city text,
  state text,
  country text not null default 'BR',
  timezone text not null default 'America/Sao_Paulo',
  currency text not null default 'BRL',
  logo_url text,
  cover_url text,
  opening_time time,
  closing_time time,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.shop_settings (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null unique references public.barber_shops(id) on delete cascade,
  booking_interval_minutes integer not null default 30,
  min_cancel_hours integer not null default 2,
  auto_confirm_appointments boolean not null default false,
  require_payment_to_confirm boolean not null default false,
  loyalty_enabled boolean not null default true,
  pix_key text,
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  plan_id uuid not null references public.plans(id) on delete restrict,
  status public.subscription_status not null default 'trialing',
  trial_ends_at timestamptz,
  current_period_starts_at timestamptz,
  current_period_ends_at timestamptz,
  external_customer_id text,
  external_subscription_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.shop_members (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role public.shop_member_role not null,
  is_active boolean not null default true,
  invited_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (barber_shop_id, user_id)
);

create table public.client_shop_relationships (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  client_id uuid not null references public.users(id) on delete cascade,
  first_seen_at timestamptz not null default now(),
  last_appointment_at timestamptz,
  notes text,
  is_blocked boolean not null default false,
  unique (barber_shop_id, client_id)
);

create table public.barbers (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  user_id uuid references public.users(id) on delete set null,
  name text not null,
  bio text,
  photo_url text,
  rating numeric(2,1) not null default 5.0,
  starting_price numeric(10,2) not null default 0,
  commission_percent numeric(5,2) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.service_categories (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid references public.barber_shops(id) on delete cascade,
  name text not null,
  icon text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  category_id uuid references public.service_categories(id) on delete set null,
  name text not null,
  description text,
  duration_minutes integer not null default 30,
  price numeric(10,2) not null,
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.barber_services (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  barber_id uuid not null references public.barbers(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete cascade,
  is_active boolean not null default true,
  unique (barber_id, service_id)
);

create table public.schedules (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  barber_id uuid not null references public.barbers(id) on delete cascade,
  weekday integer not null check (weekday between 0 and 6),
  start_time time not null,
  end_time time not null,
  slot_minutes integer not null default 30,
  is_active boolean not null default true,
  unique (barber_id, weekday, start_time)
);

create table public.blocked_times (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  barber_id uuid references public.barbers(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  reason text,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  client_id uuid references public.users(id) on delete set null,
  barber_id uuid not null references public.barbers(id) on delete restrict,
  service_id uuid not null references public.services(id) on delete restrict,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status public.appointment_status not null default 'pending',
  total_price numeric(10,2) not null,
  notes text,
  cancelled_reason text,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (barber_id, starts_at)
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  method public.payment_method not null default 'pix',
  status public.payment_status not null default 'pending',
  amount numeric(10,2) not null,
  pix_qr_code text,
  external_reference text,
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  appointment_id uuid not null unique references public.appointments(id) on delete cascade,
  client_id uuid references public.users(id) on delete set null,
  barber_id uuid not null references public.barbers(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create table public.loyalty_points (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  appointment_id uuid references public.appointments(id) on delete set null,
  points integer not null,
  description text not null,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.coupons (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  code text not null,
  description text,
  discount_percent numeric(5,2),
  discount_amount numeric(10,2),
  max_uses integer,
  used_count integer not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid references public.barber_shops(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  title text not null,
  message text not null,
  data jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.stock_items (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  name text not null,
  sku text,
  quantity integer not null default 0,
  min_quantity integer not null default 0,
  unit_cost numeric(10,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.cash_movements (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  appointment_id uuid references public.appointments(id) on delete set null,
  type public.cash_movement_type not null,
  amount numeric(10,2) not null,
  description text not null,
  movement_date date not null default current_date,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.users where id = auth.uid()
$$;

create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select role = 'admin' from public.users where id = auth.uid()), false)
$$;

create or replace function public.is_shop_member(
  target_shop_id uuid,
  allowed_roles public.shop_member_role[] default array['owner', 'manager', 'barber', 'receptionist']::public.shop_member_role[]
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    exists (
      select 1
      from public.shop_members sm
      where sm.barber_shop_id = target_shop_id
        and sm.user_id = auth.uid()
        and sm.is_active = true
        and sm.role = any(allowed_roles)
    ),
    false
  )
$$;

create or replace function public.is_shop_owner_or_manager(target_shop_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_shop_member(
    target_shop_id,
    array['owner', 'manager']::public.shop_member_role[]
  )
  or exists (
    select 1
    from public.barber_shops bs
    where bs.id = target_shop_id
      and bs.owner_id = auth.uid()
  )
  or public.is_platform_admin()
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, role)
  values (
    new.id,
    new.email,
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'client')
  );

  insert into public.profiles (user_id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  );

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

create index idx_shop_members_user on public.shop_members(user_id, is_active);
create index idx_subscriptions_shop on public.subscriptions(barber_shop_id, status);
create index idx_clients_shop on public.client_shop_relationships(barber_shop_id, client_id);
create index idx_barbers_shop on public.barbers(barber_shop_id, is_active);
create index idx_services_shop on public.services(barber_shop_id, is_active);
create index idx_barber_services_barber on public.barber_services(barber_id, is_active);
create index idx_schedules_barber on public.schedules(barber_id, weekday, is_active);
create index idx_blocked_times_shop on public.blocked_times(barber_shop_id, starts_at, ends_at);
create index idx_appointments_shop_starts on public.appointments(barber_shop_id, starts_at);
create index idx_appointments_client on public.appointments(client_id, starts_at);
create index idx_appointments_barber_starts on public.appointments(barber_id, starts_at);
create index idx_reviews_shop on public.reviews(barber_shop_id, barber_id);
create index idx_notifications_user on public.notifications(user_id, is_read);
create unique index idx_coupons_shop_code on public.coupons(barber_shop_id, lower(code));

alter table public.users enable row level security;
alter table public.profiles enable row level security;
alter table public.plans enable row level security;
alter table public.barber_shops enable row level security;
alter table public.shop_settings enable row level security;
alter table public.subscriptions enable row level security;
alter table public.shop_members enable row level security;
alter table public.client_shop_relationships enable row level security;
alter table public.barbers enable row level security;
alter table public.service_categories enable row level security;
alter table public.services enable row level security;
alter table public.barber_services enable row level security;
alter table public.schedules enable row level security;
alter table public.blocked_times enable row level security;
alter table public.appointments enable row level security;
alter table public.payments enable row level security;
alter table public.reviews enable row level security;
alter table public.loyalty_points enable row level security;
alter table public.coupons enable row level security;
alter table public.notifications enable row level security;
alter table public.stock_items enable row level security;
alter table public.cash_movements enable row level security;

create policy "users read own row" on public.users
for select using (auth.uid() = id or public.is_platform_admin());

create policy "profiles read own" on public.profiles
for select using (auth.uid() = user_id or public.is_platform_admin());

create policy "profiles update own" on public.profiles
for update using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "plans read active" on public.plans
for select using (is_active = true or public.is_platform_admin());

create policy "shops read active" on public.barber_shops
for select using (is_active = true or public.is_shop_member(id) or public.is_platform_admin());

create policy "shops create by authenticated owner" on public.barber_shops
for insert with check (auth.uid() = owner_id);

create policy "shops update by owner or manager" on public.barber_shops
for update using (public.is_shop_owner_or_manager(id))
with check (public.is_shop_owner_or_manager(id));

create policy "settings read by staff" on public.shop_settings
for select using (public.is_shop_member(barber_shop_id) or public.is_platform_admin());

create policy "settings manage by owner or manager" on public.shop_settings
for all using (public.is_shop_owner_or_manager(barber_shop_id))
with check (public.is_shop_owner_or_manager(barber_shop_id));

create policy "subscriptions read by owner or manager" on public.subscriptions
for select using (public.is_shop_owner_or_manager(barber_shop_id));

create policy "subscriptions manage by platform admin" on public.subscriptions
for all using (public.is_platform_admin())
with check (public.is_platform_admin());

create policy "members read by shop staff" on public.shop_members
for select using (public.is_shop_member(barber_shop_id) or public.is_platform_admin());

create policy "members manage by owner or manager" on public.shop_members
for all using (public.is_shop_owner_or_manager(barber_shop_id))
with check (public.is_shop_owner_or_manager(barber_shop_id));

create policy "client relationships read own or staff" on public.client_shop_relationships
for select using (
  auth.uid() = client_id
  or public.is_shop_member(barber_shop_id)
  or public.is_platform_admin()
);

create policy "client relationships manage by staff" on public.client_shop_relationships
for all using (public.is_shop_member(barber_shop_id))
with check (public.is_shop_member(barber_shop_id));

create policy "barbers read active" on public.barbers
for select using (is_active = true or public.is_shop_member(barber_shop_id) or public.is_platform_admin());

create policy "barbers manage by owner or manager" on public.barbers
for all using (public.is_shop_owner_or_manager(barber_shop_id))
with check (public.is_shop_owner_or_manager(barber_shop_id));

create policy "categories read public or staff" on public.service_categories
for select using (
  barber_shop_id is null
  or is_active = true
  or public.is_shop_member(barber_shop_id)
  or public.is_platform_admin()
);

create policy "categories manage by shop owner or manager" on public.service_categories
for all using (
  barber_shop_id is not null and public.is_shop_owner_or_manager(barber_shop_id)
)
with check (
  barber_shop_id is not null and public.is_shop_owner_or_manager(barber_shop_id)
);

create policy "services read active" on public.services
for select using (is_active = true or public.is_shop_member(barber_shop_id) or public.is_platform_admin());

create policy "services manage by owner or manager" on public.services
for all using (public.is_shop_owner_or_manager(barber_shop_id))
with check (public.is_shop_owner_or_manager(barber_shop_id));

create policy "barber services read active" on public.barber_services
for select using (is_active = true or public.is_shop_member(barber_shop_id) or public.is_platform_admin());

create policy "barber services manage by owner or manager" on public.barber_services
for all using (public.is_shop_owner_or_manager(barber_shop_id))
with check (public.is_shop_owner_or_manager(barber_shop_id));

create policy "schedules read active" on public.schedules
for select using (is_active = true or public.is_shop_member(barber_shop_id) or public.is_platform_admin());

create policy "schedules manage by shop staff" on public.schedules
for all using (public.is_shop_member(barber_shop_id))
with check (public.is_shop_member(barber_shop_id));

create policy "blocked times read for booking" on public.blocked_times
for select using (true);

create policy "blocked times manage by shop staff" on public.blocked_times
for all using (public.is_shop_member(barber_shop_id))
with check (public.is_shop_member(barber_shop_id));

create policy "appointments read involved users" on public.appointments
for select using (
  auth.uid() = client_id
  or public.is_shop_member(barber_shop_id)
  or public.is_platform_admin()
);

create policy "clients create own appointments" on public.appointments
for insert with check (
  auth.uid() = client_id
  and exists (
    select 1
    from public.barber_shops bs
    where bs.id = barber_shop_id
      and bs.is_active = true
  )
);

create policy "shop staff create appointments" on public.appointments
for insert with check (public.is_shop_member(barber_shop_id));

create policy "clients update own appointments" on public.appointments
for update using (auth.uid() = client_id)
with check (auth.uid() = client_id);

create policy "shop staff update appointments" on public.appointments
for update using (public.is_shop_member(barber_shop_id))
with check (public.is_shop_member(barber_shop_id));

create policy "payments read involved users" on public.payments
for select using (
  public.is_shop_member(barber_shop_id)
  or public.is_platform_admin()
  or exists (
    select 1
    from public.appointments a
    where a.id = appointment_id
      and a.client_id = auth.uid()
  )
);

create policy "payments manage by shop staff" on public.payments
for all using (public.is_shop_member(barber_shop_id))
with check (public.is_shop_member(barber_shop_id));

create policy "reviews read public" on public.reviews
for select using (true);

create policy "clients create own reviews" on public.reviews
for insert with check (auth.uid() = client_id);

create policy "loyalty read own or shop staff" on public.loyalty_points
for select using (
  auth.uid() = user_id
  or public.is_shop_member(barber_shop_id)
  or public.is_platform_admin()
);

create policy "loyalty manage by shop staff" on public.loyalty_points
for all using (public.is_shop_member(barber_shop_id))
with check (public.is_shop_member(barber_shop_id));

create policy "coupons read active by shop" on public.coupons
for select using (is_active = true or public.is_shop_member(barber_shop_id));

create policy "coupons manage by owner or manager" on public.coupons
for all using (public.is_shop_owner_or_manager(barber_shop_id))
with check (public.is_shop_owner_or_manager(barber_shop_id));

create policy "notifications read own" on public.notifications
for select using (auth.uid() = user_id);

create policy "notifications update own" on public.notifications
for update using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "notifications create by shop staff" on public.notifications
for insert with check (
  barber_shop_id is null
  or public.is_shop_member(barber_shop_id)
  or public.is_platform_admin()
);

create policy "stock read by shop staff" on public.stock_items
for select using (public.is_shop_member(barber_shop_id) or public.is_platform_admin());

create policy "stock manage by owner or manager" on public.stock_items
for all using (public.is_shop_owner_or_manager(barber_shop_id))
with check (public.is_shop_owner_or_manager(barber_shop_id));

create policy "cash read by owner or manager" on public.cash_movements
for select using (public.is_shop_owner_or_manager(barber_shop_id));

create policy "cash manage by owner or manager" on public.cash_movements
for all using (public.is_shop_owner_or_manager(barber_shop_id))
with check (public.is_shop_owner_or_manager(barber_shop_id));

insert into public.plans (name, slug, monthly_price, max_barbers, max_shops, features) values
  ('Básico', 'basico', 49.90, 2, 1, '{"agenda": true, "relatorios": false, "estoque": false}'::jsonb),
  ('Pro', 'pro', 99.90, 8, 1, '{"agenda": true, "relatorios": true, "estoque": false, "cupons": true}'::jsonb),
  ('Premium', 'premium', 199.90, 30, 3, '{"agenda": true, "relatorios": true, "estoque": true, "cupons": true, "multi_unidade": true}'::jsonb)
on conflict (slug) do nothing;

insert into public.service_categories (name, icon, sort_order) values
  ('Cabelo', 'content_cut', 1),
  ('Barba', 'face', 2),
  ('Combo', 'bolt', 3),
  ('Sobrancelha', 'visibility', 4)
on conflict do nothing;

insert into storage.buckets (id, name, public)
values ('barbershop-media', 'barbershop-media', true)
on conflict (id) do nothing;
