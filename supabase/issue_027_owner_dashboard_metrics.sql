-- ISSUE-027 - Indicadores reais do painel do dono
begin;

create index if not exists idx_appointments_dashboard_shop_start_status
on public.appointments(barber_shop_id, starts_at, status);

create index if not exists idx_product_sales_dashboard_shop_sold_status
on public.product_sales(barber_shop_id, sold_at, status);

create or replace function public.get_owner_dashboard_metrics(
  p_barber_shop_id uuid,
  p_from date,
  p_to date
)
returns table(
  appointments bigint,
  confirmed_appointments bigint,
  projected_revenue numeric,
  realized_revenue numeric,
  average_ticket numeric
)
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_appointments bigint;
  v_confirmed bigint;
  v_projected numeric;
  v_realized numeric;
begin
  if not exists (
    select 1 from public.barber_shops
    where id = p_barber_shop_id and owner_id = auth.uid()
  ) then
    raise exception 'Acesso negado ao painel desta barbearia.';
  end if;

  select count(*) filter (where status <> 'cancelled'),
         count(*) filter (where status in ('confirmed', 'completed')),
         coalesce(sum(total_price) filter (where status in ('pending', 'confirmed', 'completed')), 0),
         coalesce(sum(total_price) filter (where status = 'completed'), 0)
    into v_appointments, v_confirmed, v_projected, v_realized
    from public.appointments
   where barber_shop_id = p_barber_shop_id
     and starts_at >= p_from::timestamp
     and starts_at < p_to::timestamp;

  return query select v_appointments, v_confirmed, v_projected, v_realized,
    case when v_confirmed = 0 then 0 else v_projected / v_confirmed end;
end;
$$;

revoke all on function public.get_owner_dashboard_metrics(uuid, date, date) from public, anon;
grant execute on function public.get_owner_dashboard_metrics(uuid, date, date) to authenticated;
commit;
