-- ISSUE-028 - Filtros de período e série diária do painel do dono
begin;

create index if not exists idx_payments_dashboard_shop_status_paid_at
on public.payments(barber_shop_id, status, paid_at)
where status = 'paid';

drop function if exists public.get_owner_dashboard_metrics(uuid, date, date);

create or replace function public.get_owner_dashboard_metrics(
  p_barber_shop_id uuid,
  p_days integer default 7
)
returns table(
  appointments bigint,
  confirmed_appointments bigint,
  projected_revenue numeric,
  realized_revenue numeric,
  average_ticket numeric,
  daily_trend jsonb
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_timezone text;
  v_today date;
  v_from date;
  v_start timestamptz;
  v_end timestamptz;
  v_appointments bigint;
  v_confirmed bigint;
  v_completed bigint;
  v_projected numeric;
  v_appointment_received numeric;
  v_realized numeric;
  v_trend jsonb;
begin
  if p_days is null or p_days not in (1, 7, 30) then
    raise exception 'Período inválido para os indicadores.';
  end if;

  if not public.is_shop_owner_or_manager(p_barber_shop_id) then
    raise exception 'Acesso negado ao painel desta barbearia.';
  end if;

  select coalesce(shop.timezone, 'America/Sao_Paulo')
    into v_timezone
    from public.barber_shops shop
   where shop.id = p_barber_shop_id;

  if v_timezone is null then
    raise exception 'Barbearia não encontrada.';
  end if;

  v_today := (now() at time zone v_timezone)::date;
  v_from := v_today - (p_days - 1);
  v_start := v_from::timestamp at time zone v_timezone;
  v_end := (v_today + 1)::timestamp at time zone v_timezone;

  select count(*) filter (where appointment.status <> 'cancelled'),
         count(*) filter (where appointment.status = 'confirmed'),
         count(*) filter (where appointment.status = 'completed'),
         coalesce(sum(appointment.total_price) filter (
           where appointment.status in ('pending', 'confirmed')
         ), 0)
    into v_appointments, v_confirmed, v_completed, v_projected
    from public.appointments appointment
   where appointment.barber_shop_id = p_barber_shop_id
     and appointment.starts_at >= v_start
     and appointment.starts_at < v_end;

  select coalesce((
           select sum(payment.amount)
             from public.payments payment
             join public.appointments appointment
               on appointment.id = payment.appointment_id
            where payment.barber_shop_id = p_barber_shop_id
              and payment.status = 'paid'
              and payment.paid_at >= v_start
              and payment.paid_at < v_end
         ), 0)
    into v_appointment_received;

  select coalesce(v_appointment_received, 0)
       + coalesce((
           select sum(sale.total)
             from public.product_sales sale
            where sale.barber_shop_id = p_barber_shop_id
              and sale.status = 'completed'
              and sale.sold_at >= v_start
              and sale.sold_at < v_end
         ), 0)
    into v_realized;

  with days as (
    select generate_series(v_from::timestamp, v_today::timestamp,
                           interval '1 day')::date as day
  ), appointment_totals as (
    select (appointment.starts_at at time zone v_timezone)::date as day,
           count(*) filter (where appointment.status <> 'cancelled') as amount
      from public.appointments appointment
     where appointment.barber_shop_id = p_barber_shop_id
       and appointment.starts_at >= v_start
       and appointment.starts_at < v_end
     group by 1
  ), payment_totals as (
    select (payment.paid_at at time zone v_timezone)::date as day,
           sum(payment.amount) as amount
      from public.payments payment
     where payment.barber_shop_id = p_barber_shop_id
       and payment.status = 'paid'
       and payment.paid_at >= v_start
       and payment.paid_at < v_end
     group by 1
  ), sale_totals as (
    select (sale.sold_at at time zone v_timezone)::date as day,
           sum(sale.total) as amount
      from public.product_sales sale
     where sale.barber_shop_id = p_barber_shop_id
       and sale.status = 'completed'
       and sale.sold_at >= v_start
       and sale.sold_at < v_end
     group by 1
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'date', to_char(days.day, 'YYYY-MM-DD'),
           'appointments', coalesce(appointment_totals.amount, 0),
           'realized_revenue', coalesce(payment_totals.amount, 0)
                              + coalesce(sale_totals.amount, 0)
         ) order by days.day), '[]'::jsonb)
    into v_trend
    from days
    left join appointment_totals using (day)
    left join payment_totals using (day)
    left join sale_totals using (day);

  return query select v_appointments, v_confirmed, v_projected, v_realized,
    case when v_completed = 0 then 0
         else coalesce(v_appointment_received, 0) / v_completed end,
    v_trend;
end;
$$;

revoke all on function public.get_owner_dashboard_metrics(uuid, integer)
from public, anon;
grant execute on function public.get_owner_dashboard_metrics(uuid, integer)
to authenticated;

commit;
