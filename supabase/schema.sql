create extension if not exists "pgcrypto";

create type public.user_role as enum ('client', 'barber', 'admin', 'owner');
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

create table public.barber_shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.users(id) on delete set null,
  name text not null,
  description text,
  phone text,
  address text,
  city text,
  state text,
  logo_url text,
  cover_url text,
  opening_time time,
  closing_time time,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.barbers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete set null,
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  name text not null,
  bio text,
  photo_url text,
  rating numeric(2,1) not null default 5.0,
  starting_price numeric(10,2) not null default 0,
  commission_percent numeric(5,2) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.service_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  icon text,
  sort_order integer not null default 0,
  is_active boolean not null default true
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
  created_at timestamptz not null default now()
);

create table public.schedules (
  id uuid primary key default gen_random_uuid(),
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
  barber_id uuid not null references public.barbers(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  reason text,
  created_at timestamptz not null default now()
);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.users(id) on delete set null,
  barber_id uuid not null references public.barbers(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete restrict,
  appointment_date date not null,
  appointment_time time not null,
  status public.appointment_status not null default 'pending',
  total_price numeric(10,2) not null,
  notes text,
  cancelled_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (barber_id, appointment_date, appointment_time)
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
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
  appointment_id uuid not null unique references public.appointments(id) on delete cascade,
  client_id uuid references public.users(id) on delete set null,
  barber_id uuid not null references public.barbers(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create table public.loyalty_points (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  appointment_id uuid references public.appointments(id) on delete set null,
  points integer not null,
  description text not null,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
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

create index idx_barbers_shop on public.barbers(barber_shop_id);
create index idx_services_shop on public.services(barber_shop_id);
create index idx_appointments_client on public.appointments(client_id);
create index idx_appointments_barber_date on public.appointments(barber_id, appointment_date);
create index idx_notifications_user on public.notifications(user_id, is_read);

alter table public.users enable row level security;
alter table public.profiles enable row level security;
alter table public.barber_shops enable row level security;
alter table public.barbers enable row level security;
alter table public.service_categories enable row level security;
alter table public.services enable row level security;
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

create policy "read active shops" on public.barber_shops
for select using (is_active = true);

create policy "read active barbers" on public.barbers
for select using (is_active = true);

create policy "read active categories" on public.service_categories
for select using (is_active = true);

create policy "read active services" on public.services
for select using (is_active = true);

create policy "users read own row" on public.users
for select using (auth.uid() = id);

create policy "profiles read own" on public.profiles
for select using (auth.uid() = user_id);

create policy "profiles update own" on public.profiles
for update using (auth.uid() = user_id);

create policy "appointments read involved users" on public.appointments
for select using (
  auth.uid() = client_id or exists (
    select 1 from public.barbers b where b.id = barber_id and b.user_id = auth.uid()
  )
);

create policy "clients create appointments" on public.appointments
for insert with check (auth.uid() = client_id);

create policy "clients update own appointments" on public.appointments
for update using (auth.uid() = client_id);

create policy "barbers update own appointments" on public.appointments
for update using (
  exists (select 1 from public.barbers b where b.id = barber_id and b.user_id = auth.uid())
);

create policy "reviews read public" on public.reviews
for select using (true);

create policy "clients create own reviews" on public.reviews
for insert with check (auth.uid() = client_id);

create policy "payments read appointment owner" on public.payments
for select using (
  exists (
    select 1 from public.appointments a
    where a.id = appointment_id and a.client_id = auth.uid()
  )
);

create policy "loyalty read own" on public.loyalty_points
for select using (auth.uid() = user_id);

create policy "coupons read active" on public.coupons
for select using (is_active = true);

create policy "notifications read own" on public.notifications
for select using (auth.uid() = user_id);

create policy "notifications update own" on public.notifications
for update using (auth.uid() = user_id);

create policy "schedules read active" on public.schedules
for select using (is_active = true);

create policy "blocked times read" on public.blocked_times
for select using (true);

insert into public.service_categories (name, icon, sort_order) values
  ('Cabelo', 'content_cut', 1),
  ('Barba', 'face', 2),
  ('Combo', 'bolt', 3),
  ('Sobrancelha', 'visibility', 4);

insert into storage.buckets (id, name, public)
values ('barbershop-media', 'barbershop-media', true)
on conflict (id) do nothing;
