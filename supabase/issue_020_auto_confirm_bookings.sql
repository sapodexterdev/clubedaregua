-- ISSUE-020 - Confirmacao automatica e atomica dos agendamentos.
-- Novos pedidos entram imediatamente na agenda, sem acao manual da equipe.

alter table public.shop_settings
  alter column auto_confirm_appointments set default true;

update public.shop_settings
set auto_confirm_appointments = true
where auto_confirm_appointments is distinct from true;

create or replace function public.convert_booking_request_internal(
  p_request_id uuid,
  p_require_staff boolean
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  request_row public.booking_requests%rowtype;
  service_duration integer;
  shop_timezone text;
  appointment_start timestamptz;
  appointment_end timestamptz;
  created_appointment_id uuid;
begin
  select * into request_row
  from public.booking_requests
  where id = p_request_id
  for update;

  if not found then
    raise exception 'Solicitacao nao encontrada.';
  end if;
  if p_require_staff
    and not (
      public.is_shop_member(request_row.barber_shop_id)
      or public.is_platform_admin()
    )
  then
    raise exception 'Sem permissao para aceitar esta solicitacao.';
  end if;
  if request_row.appointment_id is not null then
    return request_row.appointment_id;
  end if;
  if request_row.status not in ('new', 'contacted') then
    raise exception 'Esta solicitacao nao pode mais ser aceita.';
  end if;

  select service.duration_minutes
  into service_duration
  from public.services service
  where service.id = request_row.service_id
    and service.barber_shop_id = request_row.barber_shop_id
    and service.is_active = true;

  if service_duration is null then
    raise exception 'Servico indisponivel para agendamento.';
  end if;

  select coalesce(nullif(shop.timezone, ''), 'America/Sao_Paulo')
  into shop_timezone
  from public.barber_shops shop
  where shop.id = request_row.barber_shop_id
    and shop.is_active = true;

  if shop_timezone is null then
    raise exception 'Barbearia indisponivel para agendamento.';
  end if;

  appointment_start :=
    (request_row.requested_date + request_row.requested_time)
    at time zone shop_timezone;
  appointment_end := appointment_start + make_interval(mins => service_duration);

  perform pg_advisory_xact_lock(
    hashtextextended(request_row.barber_id::text, 0)
  );

  if exists (
    select 1
    from public.appointments appointment
    where appointment.barber_id = request_row.barber_id
      and appointment.status in ('pending', 'confirmed')
      and appointment.starts_at < appointment_end
      and appointment.ends_at > appointment_start
  ) then
    raise exception 'O horario escolhido ja esta ocupado.';
  end if;

  insert into public.appointments (
    barber_shop_id,
    client_id,
    barber_id,
    service_id,
    starts_at,
    ends_at,
    status,
    total_price,
    notes,
    created_by
  ) values (
    request_row.barber_shop_id,
    request_row.client_id,
    request_row.barber_id,
    request_row.service_id,
    appointment_start,
    appointment_end,
    'confirmed',
    request_row.total_price,
    request_row.notes,
    auth.uid()
  )
  returning id into created_appointment_id;

  update public.booking_requests
  set status = 'converted', appointment_id = created_appointment_id
  where id = request_row.id;

  return created_appointment_id;
end;
$$;

create or replace function public.accept_booking_request(p_request_id uuid)
returns uuid
language sql
security definer
set search_path = public
as $$
  select public.convert_booking_request_internal(p_request_id, true);
$$;

create or replace function public.auto_confirm_booking_request()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status <> 'new' or new.appointment_id is not null then
    return new;
  end if;

  perform public.convert_booking_request_internal(new.id, false);

  return new;
end;
$$;

drop trigger if exists auto_confirm_booking_request
on public.booking_requests;
create trigger auto_confirm_booking_request
after insert on public.booking_requests
for each row execute function public.auto_confirm_booking_request();

revoke all on function public.convert_booking_request_internal(uuid, boolean)
from public, anon, authenticated;
revoke all on function public.auto_confirm_booking_request()
from public, anon, authenticated;
revoke all on function public.accept_booking_request(uuid) from public;
grant execute on function public.accept_booking_request(uuid) to authenticated;
