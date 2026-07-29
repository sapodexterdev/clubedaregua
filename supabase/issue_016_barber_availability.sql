-- ISSUE-016 - disponibilidade semanal funcional
-- 1. Cria uma jornada inicial para barbeiros ativos ainda sem agenda.
-- 2. Permite substituir a semana inteira de forma atomica e segura.

insert into public.schedules (
  barber_shop_id,
  barber_id,
  weekday,
  start_time,
  end_time,
  slot_minutes,
  is_active
)
select
  barber.barber_shop_id,
  barber.id,
  day.weekday,
  day.start_time,
  day.end_time,
  30,
  true
from public.barbers barber
cross join (
  values
    (1, time '09:00', time '18:00'),
    (2, time '09:00', time '18:00'),
    (3, time '09:00', time '18:00'),
    (4, time '09:00', time '18:00'),
    (5, time '09:00', time '18:00'),
    (6, time '09:00', time '14:00')
) as day(weekday, start_time, end_time)
where barber.is_active = true
  and not exists (
    select 1
    from public.schedules existing
    where existing.barber_id = barber.id
  )
on conflict (barber_id, weekday, start_time) do nothing;

insert into public.barber_services (
  barber_shop_id,
  barber_id,
  service_id,
  is_active
)
select
  barber.barber_shop_id,
  barber.id,
  service.id,
  true
from public.barbers barber
join public.services service
  on service.barber_shop_id = barber.barber_shop_id
 and service.is_active = true
where barber.is_active = true
on conflict (barber_id, service_id) do update
set is_active = true;

create or replace function public.replace_barber_weekly_schedule(
  p_barber_id uuid,
  p_days jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_shop_id uuid;
  day jsonb;
  day_weekday integer;
  day_start time;
  day_end time;
  day_slot_minutes integer;
begin
  if auth.uid() is null then
    raise exception 'Faça login para configurar a agenda.';
  end if;

  select barber_shop_id
    into target_shop_id
  from public.barbers
  where id = p_barber_id
    and is_active = true;

  if target_shop_id is null then
    raise exception 'Barbeiro não encontrado ou inativo.';
  end if;

  if not (
    public.is_shop_member(target_shop_id)
    or public.is_platform_admin()
  ) then
    raise exception 'Você não tem permissão para alterar esta agenda.';
  end if;

  if coalesce(jsonb_typeof(p_days), 'null') <> 'array' then
    raise exception 'Informe uma jornada semanal válida.';
  end if;

  delete from public.schedules
  where barber_id = p_barber_id;

  for day in select value from jsonb_array_elements(p_days)
  loop
    if coalesce((day ->> 'is_active')::boolean, false) = false then
      continue;
    end if;

    day_weekday := (day ->> 'weekday')::integer;
    day_start := (day ->> 'start_time')::time;
    day_end := (day ->> 'end_time')::time;
    day_slot_minutes := coalesce((day ->> 'slot_minutes')::integer, 30);

    if day_weekday < 0 or day_weekday > 6 then
      raise exception 'Dia da semana inválido.';
    end if;
    if day_end <= day_start then
      raise exception 'O horário final deve ser posterior ao inicial.';
    end if;
    if day_slot_minutes <= 0 then
      raise exception 'A duração do intervalo deve ser positiva.';
    end if;

    insert into public.schedules (
      barber_shop_id,
      barber_id,
      weekday,
      start_time,
      end_time,
      slot_minutes,
      is_active
    )
    values (
      target_shop_id,
      p_barber_id,
      day_weekday,
      day_start,
      day_end,
      day_slot_minutes,
      true
    );
  end loop;
end;
$$;

revoke all on function public.replace_barber_weekly_schedule(uuid, jsonb)
from public;

grant execute on function public.replace_barber_weekly_schedule(uuid, jsonb)
to authenticated;

comment on function public.replace_barber_weekly_schedule(uuid, jsonb)
is 'Substitui atomicamente a disponibilidade semanal de um barbeiro.';
