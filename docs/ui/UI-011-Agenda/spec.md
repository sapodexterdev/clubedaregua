# Spec — UI-011 Agenda

## Estrutura

1. título `Agenda`;
2. lista privada de solicitações ordenada por data e horário;
3. cards com barbearia, serviço, profissional, data, horário, valor e status;
4. cancelamento com confirmação para status permitidos;
5. navegação inferior oficial.

## Status

- `new`: Solicitado;
- `contacted`: Em contato;
- `converted`: Confirmado;
- `cancelled`: Cancelado.

## Regras funcionais

- usar token autenticado nas consultas e atualizações;
- RLS restringe leitura e cancelamento a `auth.uid() = client_id`;
- atualizar por gesto de pull-to-refresh;
- não exibir ação de avaliação sem avaliações reais implementadas;
- não exibir cancelamento para solicitações convertidas ou canceladas;
- falha no cancelamento mantém o card e informa o usuário.
