# Spec — UI-015 Conversão de agendamento

## Fluxo

1. o Cliente confirma as escolhas e envia o agendamento;
2. o Supabase valida permissão, serviço e disponibilidade;
3. um registro confirmado é criado em `appointments`;
4. a solicitação recebe `status = converted` e o `appointment_id`;
5. o cliente recebe uma notificação;
6. Dono ou Barbeiro autorizado pode concluir o atendimento pela agenda;
7. o cliente recebe uma notificação de conclusão.

## Segurança

- as operações são RPCs transacionais;
- a confirmação automática e a conclusão usam RPCs distintas, cada uma com a
  autorização adequada; somente Dono, Barbeiro autorizado ou administrador de
  plataforma pode concluir o atendimento;
- o barbeiro é bloqueado durante a validação do horário;
- uma solicitação já convertida retorna o mesmo agendamento.
