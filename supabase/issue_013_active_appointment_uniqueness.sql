-- ISSUE-013 - Horarios concluidos ou cancelados nao bloqueiam novos atendimentos
-- Execute este arquivo uma vez no SQL Editor do Supabase.

alter table public.appointments
drop constraint if exists appointments_barber_id_starts_at_key;

create unique index if not exists idx_appointments_active_start_unique
on public.appointments(barber_id, starts_at)
where status in ('pending', 'confirmed');
