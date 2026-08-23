# UI-011 — Agenda

## Objetivo

Permitir que o cliente autenticado acompanhe e, quando permitido, cancele seus
próprios agendamentos confirmados automaticamente, com dados reais e privados.

## Status

Em validação após execução de `supabase/issue_009_client_booking_requests.sql`.

## Princípios

- nenhuma informação simulada;
- acesso limitado ao proprietário do agendamento por RLS;
- status compatíveis com o fluxo operacional automático;
- cancelamento somente enquanto o agendamento permitir essa ação;
- estados de carregamento, vazio e erro explícitos.
