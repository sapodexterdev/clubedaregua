# UI-011 — Agenda

## Objetivo

Permitir que o cliente autenticado acompanhe e cancele suas próprias solicitações de horário com dados reais e privados.

## Status

Em validação após execução de `supabase/issue_009_client_booking_requests.sql`.

## Princípios

- nenhuma informação simulada;
- acesso limitado ao proprietário da solicitação por RLS;
- status compatíveis com o fluxo operacional;
- cancelamento somente enquanto a solicitação estiver aberta;
- estados de carregamento, vazio e erro explícitos.
