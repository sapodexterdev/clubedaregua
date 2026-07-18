# Spec — UI-015 Conversão de agendamento

## Fluxo

1. a Gestão aceita uma solicitação nova ou contatada;
2. o Supabase valida permissão, serviço e disponibilidade;
3. um registro confirmado é criado em `appointments`;
4. a solicitação recebe `status = converted` e o `appointment_id`;
5. o cliente recebe uma notificação;
6. a Gestão pode concluir o atendimento pela agenda;
7. o cliente recebe uma notificação de conclusão.

## Segurança

- as operações são RPCs transacionais;
- somente membros da unidade ou administrador executam as RPCs;
- o barbeiro é bloqueado durante a validação do horário;
- uma solicitação já convertida retorna o mesmo agendamento.
