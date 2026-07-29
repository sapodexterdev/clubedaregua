# UI-012 — Favoritos

## Objetivo

Permitir que o cliente autenticado salve e reencontre suas barbearias preferidas.

## Status

Em validação após execução de `supabase/issue_010_client_favorites.sql`.

## Princípios

- persistência real por usuário;
- leitura e alterações protegidas por RLS;
- acesso ao perfil em uma ação;
- remoção imediata e reversível ao favoritar novamente;
- estados de carregamento, vazio e erro explícitos.
