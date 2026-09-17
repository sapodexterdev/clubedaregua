# UI-015 — Conversão automática em agendamento

## Objetivo

Garantir que a escolha enviada pelo Cliente se torne automaticamente um
agendamento real, rastreável e apto a ser concluído e avaliado, sem aceite
manual do Dono ou do Barbeiro.

## Status

Implementado, aguardando execução do SQL e validação no Preview.

## Princípios

- conversão automática e atômica;
- prevenção de conflito de horário;
- vínculo entre solicitação e agendamento;
- notificação privada do cliente;
- conclusão somente por membro autorizado da barbearia.
