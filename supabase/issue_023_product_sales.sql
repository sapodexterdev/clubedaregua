-- Issue 023: catalogo, estoque e vendas de produtos controlados pelo Dono.
-- Execute no SQL Editor do Supabase antes de publicar o frontend.

create or replace function public.is_shop_owner(target_shop_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_platform_admin() or coalesce(
    exists (
      select 1
      from public.barber_shops shop
      where shop.id = target_shop_id
        and shop.owner_id = auth.uid()
    ) or exists (
      select 1
      from public.shop_members member
      where member.barber_shop_id = target_shop_id
        and member.user_id = auth.uid()
        and member.role = 'owner'
        and member.is_active = true
    ),
    false
  )
$$;

alter table public.stock_items
  add column if not exists description text,
  add column if not exists barcode text,
  add column if not exists category text,
  add column if not exists unit text not null default 'un',
  add column if not exists sale_price numeric(10,2) not null default 0,
  add column if not exists is_active boolean not null default true;

alter table public.stock_items
  drop constraint if exists stock_items_quantity_nonnegative,
  add constraint stock_items_quantity_nonnegative check (quantity >= 0),
  drop constraint if exists stock_items_min_quantity_nonnegative,
  add constraint stock_items_min_quantity_nonnegative check (min_quantity >= 0),
  drop constraint if exists stock_items_unit_cost_nonnegative,
  add constraint stock_items_unit_cost_nonnegative check (unit_cost >= 0),
  drop constraint if exists stock_items_sale_price_nonnegative,
  add constraint stock_items_sale_price_nonnegative check (sale_price >= 0);

create unique index if not exists stock_items_shop_sku_unique
  on public.stock_items (barber_shop_id, lower(sku))
  where sku is not null and btrim(sku) <> '';

create unique index if not exists stock_items_shop_barcode_unique
  on public.stock_items (barber_shop_id, barcode)
  where barcode is not null and btrim(barcode) <> '';

create index if not exists stock_items_shop_active_name_idx
  on public.stock_items (barber_shop_id, is_active, name);

create table if not exists public.product_sales (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  status text not null default 'completed' check (status in ('completed', 'cancelled')),
  subtotal numeric(10,2) not null check (subtotal >= 0),
  discount numeric(10,2) not null default 0 check (discount >= 0),
  total numeric(10,2) not null check (total >= 0),
  payment_method text not null check (payment_method in ('pix', 'cash', 'credit_card', 'debit_card', 'other')),
  customer_name text,
  notes text,
  sold_by uuid references public.users(id) on delete set null,
  sold_at timestamptz not null default now(),
  cancelled_by uuid references public.users(id) on delete set null,
  cancelled_at timestamptz,
  cancellation_reason text,
  created_at timestamptz not null default now()
);

create table if not exists public.product_sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.product_sales(id) on delete cascade,
  stock_item_id uuid references public.stock_items(id) on delete set null,
  product_name text not null,
  sku text,
  unit text not null default 'un',
  quantity integer not null check (quantity > 0),
  unit_price numeric(10,2) not null check (unit_price >= 0),
  unit_cost numeric(10,2) not null default 0 check (unit_cost >= 0),
  line_total numeric(10,2) not null check (line_total >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  barber_shop_id uuid not null references public.barber_shops(id) on delete cascade,
  stock_item_id uuid not null references public.stock_items(id) on delete cascade,
  sale_id uuid references public.product_sales(id) on delete set null,
  movement_type text not null check (movement_type in ('initial', 'restock', 'sale', 'adjustment', 'sale_cancellation')),
  quantity_delta integer not null check (quantity_delta <> 0),
  balance_after integer not null check (balance_after >= 0),
  reason text,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists product_sales_shop_sold_at_idx
  on public.product_sales (barber_shop_id, sold_at desc);
create index if not exists product_sale_items_sale_idx
  on public.product_sale_items (sale_id);
create index if not exists stock_movements_item_created_idx
  on public.stock_movements (stock_item_id, created_at desc);

alter table public.product_sales enable row level security;
alter table public.product_sale_items enable row level security;
alter table public.stock_movements enable row level security;

drop policy if exists stock_read_staff on public.stock_items;
drop policy if exists stock_manage_owner_manager on public.stock_items;
drop policy if exists stock_read_owner on public.stock_items;
drop policy if exists stock_manage_owner on public.stock_items;
create policy stock_read_owner on public.stock_items
for select using (public.is_shop_owner(barber_shop_id));

drop policy if exists product_sales_owner on public.product_sales;
create policy product_sales_owner on public.product_sales
for select using (public.is_shop_owner(barber_shop_id));

drop policy if exists product_sale_items_owner on public.product_sale_items;
create policy product_sale_items_owner on public.product_sale_items
for select using (
  exists (
    select 1 from public.product_sales sale
    where sale.id = product_sale_items.sale_id
      and public.is_shop_owner(sale.barber_shop_id)
  )
);

drop policy if exists stock_movements_owner on public.stock_movements;
create policy stock_movements_owner on public.stock_movements
for select using (public.is_shop_owner(barber_shop_id));

drop policy if exists cash_read_owner_manager on public.cash_movements;
drop policy if exists cash_manage_owner_manager on public.cash_movements;
drop policy if exists cash_read_owner on public.cash_movements;
drop policy if exists cash_manage_owner on public.cash_movements;
create policy cash_read_owner on public.cash_movements
for select using (public.is_shop_owner(barber_shop_id));
create policy cash_manage_owner on public.cash_movements
for all using (public.is_shop_owner(barber_shop_id))
with check (public.is_shop_owner(barber_shop_id));

create or replace function public.adjust_product_stock(
  p_stock_item_id uuid,
  p_quantity_delta integer,
  p_reason text default null
)
returns public.stock_items
language plpgsql
security definer
set search_path = public
as $$
declare
  product public.stock_items;
  new_balance integer;
begin
  if p_quantity_delta = 0 then
    raise exception 'A quantidade do ajuste deve ser diferente de zero.';
  end if;

  select * into product
  from public.stock_items
  where id = p_stock_item_id
  for update;

  if product.id is null or not public.is_shop_owner(product.barber_shop_id) then
    raise exception 'Produto não encontrado ou acesso negado.';
  end if;

  new_balance := product.quantity + p_quantity_delta;
  if new_balance < 0 then
    raise exception 'O ajuste deixaria o estoque negativo.';
  end if;

  update public.stock_items
  set quantity = new_balance, updated_at = now()
  where id = product.id
  returning * into product;

  insert into public.stock_movements (
    barber_shop_id, stock_item_id, movement_type, quantity_delta,
    balance_after, reason, created_by
  ) values (
    product.barber_shop_id, product.id,
    case when p_quantity_delta > 0 then 'restock' else 'adjustment' end,
    p_quantity_delta, new_balance, nullif(btrim(p_reason), ''), auth.uid()
  );

  return product;
end;
$$;

create or replace function public.save_commerce_product(
  p_barber_shop_id uuid,
  p_product_id uuid,
  p_name text,
  p_description text,
  p_sku text,
  p_barcode text,
  p_category text,
  p_unit text,
  p_initial_quantity integer,
  p_min_quantity integer,
  p_unit_cost numeric,
  p_sale_price numeric,
  p_is_active boolean
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  product public.stock_items;
begin
  if not public.is_shop_owner(p_barber_shop_id) then
    raise exception 'Apenas o Dono pode gerenciar produtos.';
  end if;
  if btrim(coalesce(p_name, '')) = '' then
    raise exception 'Informe o nome do produto.';
  end if;
  if coalesce(p_initial_quantity, 0) < 0 or coalesce(p_min_quantity, 0) < 0
     or coalesce(p_unit_cost, 0) < 0 or coalesce(p_sale_price, 0) <= 0 then
    raise exception 'Quantidades e valores do produto são inválidos.';
  end if;

  if p_product_id is null then
    insert into public.stock_items (
      barber_shop_id, name, description, sku, barcode, category, unit,
      quantity, min_quantity, unit_cost, sale_price, is_active
    ) values (
      p_barber_shop_id, btrim(p_name), nullif(btrim(p_description), ''),
      nullif(btrim(p_sku), ''), nullif(btrim(p_barcode), ''),
      nullif(btrim(p_category), ''), coalesce(nullif(btrim(p_unit), ''), 'un'),
      p_initial_quantity, p_min_quantity, p_unit_cost, p_sale_price, p_is_active
    ) returning * into product;

    if product.quantity > 0 then
      insert into public.stock_movements (
        barber_shop_id, stock_item_id, movement_type, quantity_delta,
        balance_after, reason, created_by
      ) values (
        product.barber_shop_id, product.id, 'initial', product.quantity,
        product.quantity, 'Estoque inicial', auth.uid()
      );
    end if;
  else
    update public.stock_items
    set name = btrim(p_name),
        description = nullif(btrim(p_description), ''),
        sku = nullif(btrim(p_sku), ''),
        barcode = nullif(btrim(p_barcode), ''),
        category = nullif(btrim(p_category), ''),
        unit = coalesce(nullif(btrim(p_unit), ''), 'un'),
        min_quantity = p_min_quantity,
        unit_cost = p_unit_cost,
        sale_price = p_sale_price,
        is_active = p_is_active,
        updated_at = now()
    where id = p_product_id
      and barber_shop_id = p_barber_shop_id
    returning * into product;

    if product.id is null then
      raise exception 'Produto não encontrado ou acesso negado.';
    end if;
  end if;

  return product.id;
end;
$$;

create or replace function public.register_product_sale(
  p_barber_shop_id uuid,
  p_items jsonb,
  p_payment_method text,
  p_discount numeric default 0,
  p_customer_name text default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  sale_id uuid;
  item jsonb;
  product public.stock_items;
  requested_quantity integer;
  subtotal_value numeric(10,2) := 0;
  discount_value numeric(10,2) := greatest(coalesce(p_discount, 0), 0);
  total_value numeric(10,2);
begin
  if not public.is_shop_owner(p_barber_shop_id) then
    raise exception 'Apenas o Dono pode registrar vendas.';
  end if;
  if p_payment_method not in ('pix', 'cash', 'credit_card', 'debit_card', 'other') then
    raise exception 'Forma de pagamento inválida.';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Adicione pelo menos um produto à venda.';
  end if;
  if (
    select count(*) from jsonb_array_elements(p_items)
  ) <> (
    select count(distinct value->>'product_id') from jsonb_array_elements(p_items)
  ) then
    raise exception 'Um produto não pode aparecer mais de uma vez na venda.';
  end if;

  -- Trava todos os produtos em ordem estável para evitar corrida e deadlock.
  perform 1
  from public.stock_items product_lock
  where product_lock.id in (
    select (value->>'product_id')::uuid from jsonb_array_elements(p_items)
  )
  order by product_lock.id
  for update;

  for item in select value from jsonb_array_elements(p_items)
  loop
    requested_quantity := coalesce((item->>'quantity')::integer, 0);
    select * into product
    from public.stock_items
    where id = (item->>'product_id')::uuid
      and barber_shop_id = p_barber_shop_id;

    if product.id is null or not product.is_active then
      raise exception 'Um dos produtos não está disponível.';
    end if;
    if requested_quantity <= 0 then
      raise exception 'A quantidade de cada produto deve ser maior que zero.';
    end if;
    if product.quantity < requested_quantity then
      raise exception 'Estoque insuficiente para %.', product.name;
    end if;
    subtotal_value := subtotal_value + (product.sale_price * requested_quantity);
  end loop;

  if discount_value > subtotal_value then
    raise exception 'O desconto não pode superar o subtotal.';
  end if;
  total_value := subtotal_value - discount_value;

  insert into public.product_sales (
    barber_shop_id, subtotal, discount, total, payment_method,
    customer_name, notes, sold_by
  ) values (
    p_barber_shop_id, subtotal_value, discount_value, total_value,
    p_payment_method, nullif(btrim(p_customer_name), ''),
    nullif(btrim(p_notes), ''), auth.uid()
  ) returning id into sale_id;

  for item in select value from jsonb_array_elements(p_items)
  loop
    requested_quantity := (item->>'quantity')::integer;
    select * into product
    from public.stock_items
    where id = (item->>'product_id')::uuid;

    insert into public.product_sale_items (
      sale_id, stock_item_id, product_name, sku, unit, quantity,
      unit_price, unit_cost, line_total
    ) values (
      sale_id, product.id, product.name, product.sku, product.unit,
      requested_quantity, product.sale_price, product.unit_cost,
      product.sale_price * requested_quantity
    );

    update public.stock_items
    set quantity = quantity - requested_quantity, updated_at = now()
    where id = product.id;

    insert into public.stock_movements (
      barber_shop_id, stock_item_id, sale_id, movement_type,
      quantity_delta, balance_after, reason, created_by
    ) values (
      p_barber_shop_id, product.id, sale_id, 'sale', -requested_quantity,
      product.quantity - requested_quantity, 'Venda de produtos', auth.uid()
    );
  end loop;

  insert into public.cash_movements (
    barber_shop_id, type, amount, description, movement_date, created_by
  ) values (
    p_barber_shop_id, 'income', total_value,
    'Venda de produtos #' || left(sale_id::text, 8), current_date, auth.uid()
  );

  return sale_id;
end;
$$;

create or replace function public.cancel_product_sale(
  p_sale_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  sale public.product_sales;
  sale_item public.product_sale_items;
  product public.stock_items;
begin
  select * into sale
  from public.product_sales
  where id = p_sale_id
  for update;

  if sale.id is null or not public.is_shop_owner(sale.barber_shop_id) then
    raise exception 'Venda não encontrada ou acesso negado.';
  end if;
  if sale.status = 'cancelled' then
    raise exception 'Esta venda já foi cancelada.';
  end if;
  if btrim(coalesce(p_reason, '')) = '' then
    raise exception 'Informe o motivo do cancelamento.';
  end if;

  for sale_item in
    select * from public.product_sale_items
    where sale_id = sale.id
    order by stock_item_id
  loop
    if sale_item.stock_item_id is null then
      continue;
    end if;
    select * into product
    from public.stock_items
    where id = sale_item.stock_item_id
    for update;
    if product.id is null then
      continue;
    end if;

    update public.stock_items
    set quantity = quantity + sale_item.quantity, updated_at = now()
    where id = product.id;

    insert into public.stock_movements (
      barber_shop_id, stock_item_id, sale_id, movement_type,
      quantity_delta, balance_after, reason, created_by
    ) values (
      sale.barber_shop_id, product.id, sale.id, 'sale_cancellation',
      sale_item.quantity, product.quantity + sale_item.quantity,
      btrim(p_reason), auth.uid()
    );
  end loop;

  update public.product_sales
  set status = 'cancelled', cancelled_by = auth.uid(),
      cancelled_at = now(), cancellation_reason = btrim(p_reason)
  where id = sale.id;

  insert into public.cash_movements (
    barber_shop_id, type, amount, description, movement_date, created_by
  ) values (
    sale.barber_shop_id, 'expense', sale.total,
    'Estorno da venda #' || left(sale.id::text, 8), current_date, auth.uid()
  );
end;
$$;

revoke all on function public.adjust_product_stock(uuid, integer, text) from public;
revoke all on function public.save_commerce_product(uuid, uuid, text, text, text, text, text, text, integer, integer, numeric, numeric, boolean) from public;
revoke all on function public.register_product_sale(uuid, jsonb, text, numeric, text, text) from public;
revoke all on function public.cancel_product_sale(uuid, text) from public;
grant execute on function public.adjust_product_stock(uuid, integer, text) to authenticated;
grant execute on function public.save_commerce_product(uuid, uuid, text, text, text, text, text, text, integer, integer, numeric, numeric, boolean) to authenticated;
grant execute on function public.register_product_sale(uuid, jsonb, text, numeric, text, text) to authenticated;
grant execute on function public.cancel_product_sale(uuid, text) to authenticated;

notify pgrst, 'reload schema';
