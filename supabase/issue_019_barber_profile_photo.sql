-- Permite ao barbeiro atualizar somente a foto do próprio perfil.
-- A função evita conceder UPDATE amplo na tabela public.barbers.

create or replace function public.update_my_barber_photo(
  p_barber_id uuid,
  p_photo_url text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_barber public.barbers%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada obrigatória.' using errcode = '28000';
  end if;

  update public.barbers
  set photo_url = nullif(trim(coalesce(p_photo_url, '')), '')
  where id = p_barber_id
    and user_id = auth.uid()
    and is_active = true
  returning * into updated_barber;

  if updated_barber.id is null then
    raise exception 'Perfil de barbeiro não encontrado para o usuário atual.'
      using errcode = 'P0002';
  end if;

  return to_jsonb(updated_barber);
end;
$$;

revoke all on function public.update_my_barber_photo(uuid, text) from public;
grant execute on function public.update_my_barber_photo(uuid, text) to authenticated;
