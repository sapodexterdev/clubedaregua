-- ISSUE-024 - Disponibilidade fail-closed e integridade atomica da agenda.
-- Requer ISSUE-020 aplicado para a confirmacao automatica de booking_requests.
-- Execute uma vez no SQL Editor do Supabase antes de publicar o frontend.

do $$
begin
  if not exists (
    select 1
    from pg_trigger trigger_row
    where trigger_row.tgrelid = 'public.booking_requests'::regclass
      and trigger_row.tgname = 'auto_confirm_booking_request'
      and trigger_row.tgenabled in ('O', 'A')
  ) then
    raise exception
      'ISSUE-020 precisa ser aplicado antes: trigger auto_confirm_booking_request ausente.';
  end if;
end;
$$;

do $$
begin
  if exists (
    select 1
    from public.blocked_times blocked
    left join public.barbers barber
      on barber.id = blocked.barber_id
     and barber.barber_shop_id = blocked.barber_shop_id
    where blocked.barber_id is not null
      and barber.id is null
  ) then
    raise exception
      'Existem bloqueios vinculados a profissional de outra barbearia.';
  end if;

  if exists (
    select 1
    from public.appointments first_appointment
    join public.appointments second_appointment
      on second_appointment.barber_id = first_appointment.barber_id
     and second_appointment.id > first_appointment.id
     and second_appointment.status in ('pending', 'confirmed')
     and second_appointment.starts_at < first_appointment.ends_at
     and second_appointment.ends_at > first_appointment.starts_at
    where first_appointment.status in ('pending', 'confirmed')
  ) then
    raise exception
      'Existem agendamentos ativos sobrepostos. Corrija-os antes do ISSUE-024.';
  end if;

  if exists (
    select 1
    from public.appointments appointment
    left join public.barbers barber
      on barber.id = appointment.barber_id
     and barber.barber_shop_id = appointment.barber_shop_id
    left join public.services service
      on service.id = appointment.service_id
     and service.barber_shop_id = appointment.barber_shop_id
    where barber.id is null or service.id is null
  ) then
    raise exception
      'Existem agendamentos com profissional ou servico de outra barbearia.';
  end if;

  if exists (
    select 1
    from public.appointments appointment
    join public.blocked_times blocked
      on blocked.barber_shop_id = appointment.barber_shop_id
     and (blocked.barber_id is null or blocked.barber_id = appointment.barber_id)
     and blocked.starts_at < appointment.ends_at
     and blocked.ends_at > appointment.starts_at
    where appointment.status in ('pending', 'confirmed')
  ) then
    raise exception
      'Existem agendamentos ativos dentro de bloqueios. Corrija-os antes do ISSUE-024.';
  end if;
end;
$$;

create or replace view public.booking_interval_availability as
select
  appointment.id,
  appointment.barber_shop_id,
  appointment.barber_id,
  appointment.starts_at at time zone
    coalesce(nullif(shop.timezone, ''), 'America/Sao_Paulo') as starts_at,
  appointment.ends_at at time zone
    coalesce(nullif(shop.timezone, ''), 'America/Sao_Paulo') as ends_at
from public.appointments appointment
join public.barber_shops shop on shop.id = appointment.barber_shop_id
where appointment.status in ('pending', 'confirmed')
union all
select
  blocked.id,
  blocked.barber_shop_id,
  blocked.barber_id,
  blocked.starts_at at time zone
    coalesce(nullif(shop.timezone, ''), 'America/Sao_Paulo') as starts_at,
  blocked.ends_at at time zone
    coalesce(nullif(shop.timezone, ''), 'America/Sao_Paulo') as ends_at
from public.blocked_times blocked
join public.barber_shops shop on shop.id = blocked.barber_shop_id;

grant select on public.booking_interval_availability to anon, authenticated;

create or replace function public.lock_blocked_time_schedule()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_shop_ids uuid[] := '{}'::uuid[];
  target_barber_ids uuid[] := '{}'::uuid[];
  locked_barber_id uuid;
  candidate public.blocked_times%rowtype;
  shop_timezone text;
begin
  if tg_op in ('INSERT', 'UPDATE')
    and new.barber_id is not null
    and not exists (
      select 1
      from public.barbers barber
      where barber.id = new.barber_id
        and barber.barber_shop_id = new.barber_shop_id
    )
  then
    raise exception 'Profissional invalido para esta barbearia.';
  end if;

  if tg_op in ('UPDATE', 'DELETE') then
    if old.barber_id is null then
      target_shop_ids := array_append(target_shop_ids, old.barber_shop_id);
    else
      target_barber_ids := array_append(target_barber_ids, old.barber_id);
    end if;
  end if;

  if tg_op in ('INSERT', 'UPDATE') then
    if new.barber_id is null then
      target_shop_ids := array_append(target_shop_ids, new.barber_shop_id);
    else
      target_barber_ids := array_append(target_barber_ids, new.barber_id);
    end if;
  end if;

  for locked_barber_id in
    select distinct barber.id
    from public.barbers barber
    where barber.id = any(target_barber_ids)
       or barber.barber_shop_id = any(target_shop_ids)
    order by barber.id
  loop
    perform pg_advisory_xact_lock(hashtextextended(locked_barber_id::text, 0));
  end loop;

  if tg_op = 'DELETE' then
    return old;
  end if;

  candidate := new;

  if exists (
    select 1
    from public.appointments appointment
    where appointment.barber_shop_id = candidate.barber_shop_id
      and (candidate.barber_id is null or appointment.barber_id = candidate.barber_id)
      and appointment.status in ('pending', 'confirmed')
      and appointment.starts_at < candidate.ends_at
      and appointment.ends_at > candidate.starts_at
  ) then
    raise exception 'O bloqueio conflita com um agendamento ativo.';
  end if;

  select coalesce(nullif(shop.timezone, ''), 'America/Sao_Paulo')
  into shop_timezone
  from public.barber_shops shop
  where shop.id = candidate.barber_shop_id;

  if exists (
    select 1
    from public.booking_requests request
    join public.services service on service.id = request.service_id
    where request.barber_shop_id = candidate.barber_shop_id
      and (candidate.barber_id is null or request.barber_id = candidate.barber_id)
      and request.status in ('new', 'contacted')
      and (
        (request.requested_date + request.requested_time)
        at time zone shop_timezone
      ) < candidate.ends_at
      and (
        (request.requested_date + request.requested_time)
        at time zone shop_timezone
        + make_interval(mins => service.duration_minutes)
      ) > candidate.starts_at
  ) then
    raise exception 'O bloqueio conflita com uma solicitacao ativa.';
  end if;

  return new;
end;
$$;

drop trigger if exists lock_blocked_time_schedule on public.blocked_times;
create trigger lock_blocked_time_schedule
before insert or update or delete on public.blocked_times
for each row execute function public.lock_blocked_time_schedule();

create or replace function public.prevent_appointment_conflict()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  shop_timezone text;
begin
  if not exists (
    select 1
    from public.barbers barber
    where barber.id = new.barber_id
      and barber.barber_shop_id = new.barber_shop_id
  ) then
    raise exception 'Profissional invalido para esta barbearia.';
  end if;

  if not exists (
    select 1
    from public.services service
    where service.id = new.service_id
      and service.barber_shop_id = new.barber_shop_id
  ) then
    raise exception 'Servico invalido para esta barbearia.';
  end if;

  if new.status not in ('pending', 'confirmed') then
    return new;
  end if;

  if not exists (
    select 1
    from public.barber_shops shop
    join public.barbers barber
      on barber.id = new.barber_id
     and barber.barber_shop_id = shop.id
    join public.services service
      on service.id = new.service_id
     and service.barber_shop_id = shop.id
    where shop.id = new.barber_shop_id
      and shop.is_active = true
      and barber.is_active = true
      and service.is_active = true
  ) then
    raise exception 'Barbearia, profissional ou servico indisponivel.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(new.barber_id::text, 0));

  if exists (
    select 1
    from public.appointments appointment
    where appointment.barber_id = new.barber_id
      and appointment.id is distinct from new.id
      and appointment.status in ('pending', 'confirmed')
      and appointment.starts_at < new.ends_at
      and appointment.ends_at > new.starts_at
  ) then
    raise exception 'O horario escolhido ja esta ocupado.';
  end if;

  if exists (
    select 1
    from public.blocked_times blocked
    where blocked.barber_shop_id = new.barber_shop_id
      and (blocked.barber_id is null or blocked.barber_id = new.barber_id)
      and blocked.starts_at < new.ends_at
      and blocked.ends_at > new.starts_at
  ) then
    raise exception 'O horario escolhido esta bloqueado.';
  end if;

  if tg_op = 'UPDATE' then
    select coalesce(nullif(shop.timezone, ''), 'America/Sao_Paulo')
    into shop_timezone
    from public.barber_shops shop
    where shop.id = new.barber_shop_id;

    if exists (
      select 1
      from public.booking_requests request
      join public.services service on service.id = request.service_id
      where request.barber_id = new.barber_id
        and request.status in ('new', 'contacted')
        and (
          (request.requested_date + request.requested_time)
          at time zone shop_timezone
        ) < new.ends_at
        and (
          (request.requested_date + request.requested_time)
          at time zone shop_timezone
          + make_interval(mins => service.duration_minutes)
        ) > new.starts_at
    ) then
      raise exception 'O horario escolhido ja possui uma solicitacao ativa.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists prevent_appointment_conflict on public.appointments;
create trigger prevent_appointment_conflict
before insert or update of
  barber_shop_id,
  barber_id,
  service_id,
  starts_at,
  ends_at,
  status
on public.appointments
for each row execute function public.prevent_appointment_conflict();

create or replace function public.prevent_booking_request_conflict()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  service_duration integer;
  shop_timezone text;
  requested_start timestamptz;
  requested_end timestamptz;
begin
  if new.status not in ('new', 'contacted') then
    return new;
  end if;

  if not exists (
    select 1
    from public.barbers barber
    where barber.id = new.barber_id
      and barber.barber_shop_id = new.barber_shop_id
      and barber.is_active = true
  ) then
    raise exception 'Profissional indisponivel para esta barbearia.';
  end if;

  select service.duration_minutes
  into service_duration
  from public.services service
  where service.id = new.service_id
    and service.barber_shop_id = new.barber_shop_id
    and service.is_active = true;

  if service_duration is null then
    raise exception 'Servico indisponivel para agendamento.';
  end if;

  select coalesce(nullif(shop.timezone, ''), 'America/Sao_Paulo')
  into shop_timezone
  from public.barber_shops shop
  where shop.id = new.barber_shop_id
    and shop.is_active = true;

  if shop_timezone is null then
    raise exception 'Barbearia indisponivel para agendamento.';
  end if;

  requested_start :=
    (new.requested_date + new.requested_time) at time zone shop_timezone;
  requested_end := requested_start + make_interval(mins => service_duration);

  perform pg_advisory_xact_lock(hashtextextended(new.barber_id::text, 0));

  if exists (
    select 1
    from public.appointments appointment
    where appointment.barber_id = new.barber_id
      and appointment.status in ('pending', 'confirmed')
      and appointment.starts_at < requested_end
      and appointment.ends_at > requested_start
  ) then
    raise exception 'O horario escolhido ja esta ocupado.';
  end if;

  if exists (
    select 1
    from public.blocked_times blocked
    where blocked.barber_shop_id = new.barber_shop_id
      and (blocked.barber_id is null or blocked.barber_id = new.barber_id)
      and blocked.starts_at < requested_end
      and blocked.ends_at > requested_start
  ) then
    raise exception 'O horario escolhido esta bloqueado.';
  end if;

  if exists (
    select 1
    from public.booking_requests request
    join public.services service on service.id = request.service_id
    where request.barber_id = new.barber_id
      and request.id is distinct from new.id
      and request.status in ('new', 'contacted')
      and (
        (request.requested_date + request.requested_time)
        at time zone shop_timezone
      ) < requested_end
      and (
        (request.requested_date + request.requested_time)
        at time zone shop_timezone
        + make_interval(mins => service.duration_minutes)
      ) > requested_start
  ) then
    raise exception 'O horario escolhido ja possui uma solicitacao ativa.';
  end if;

  return new;
end;
$$;

drop trigger if exists prevent_booking_request_conflict
on public.booking_requests;
create trigger prevent_booking_request_conflict
before insert or update of
  barber_shop_id,
  barber_id,
  service_id,
  requested_date,
  requested_time,
  status
on public.booking_requests
for each row execute function public.prevent_booking_request_conflict();

-- O fluxo publico oficial cria booking_requests. Impede que o cliente contorne
-- a conversao atomica inserindo diretamente em appointments.
drop policy if exists appointments_insert_client on public.appointments;
drop policy if exists appointments_insert_staff on public.appointments;

revoke all on function public.prevent_appointment_conflict()
from public, anon, authenticated;
revoke all on function public.prevent_booking_request_conflict()
from public, anon, authenticated;
revoke all on function public.lock_blocked_time_schedule()
from public, anon, authenticated;
