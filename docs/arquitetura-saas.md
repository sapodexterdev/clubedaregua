# Arquitetura SaaS

## Objetivo

O Clube da Régua deve funcionar como uma plataforma SaaS para múltiplas barbearias. Cada barbearia possui dados, equipe, agenda, clientes, caixa e configurações próprias, isoladas por regras de banco.

## Produtos

### App Cliente

O app do cliente deve ser direto e leve. A jornada ideal é:

1. Entrar ou continuar como cliente autenticado.
2. Buscar barbearia, barbeiro ou serviço.
3. Escolher serviço.
4. Escolher profissional, data e horário.
5. Confirmar agendamento e pagamento.

O cliente não deve ver complexidade administrativa.

### App Gestão

O app do barbeiro/dono deve concentrar operação e administração:

- Agenda do dia.
- Confirmação e cancelamento de atendimentos.
- Bloqueio de horários.
- Férias e indisponibilidade.
- Cadastro de serviços e barbeiros.
- Clientes, histórico e retornos.
- Caixa, estoque, cupons e relatórios.
- Plano, assinatura e limites da conta.

## Modelo Multiempresa

`barber_shops` é a empresa principal. As tabelas operacionais usam `barber_shop_id` para isolamento:

- `shop_members`
- `shop_settings`
- `subscriptions`
- `client_shop_relationships`
- `barbers`
- `services`
- `barber_services`
- `schedules`
- `blocked_times`
- `appointments`
- `payments`
- `reviews`
- `loyalty_points`
- `coupons`
- `notifications`
- `stock_items`
- `cash_movements`

## Permissões

O schema usa RLS com funções auxiliares:

- `is_platform_admin()`
- `is_shop_member(shop_id, roles)`
- `is_shop_owner_or_manager(shop_id)`

Regras principais:

- Cliente vê seus próprios agendamentos, pontos, notificações e histórico.
- Cliente pode ler barbearias, barbeiros, serviços e horários ativos.
- Barbeiro/equipe vê e administra dados da barbearia onde é membro.
- Dono/gerente administra equipe, serviços, agenda, caixa e configurações.
- Administrador da plataforma pode operar suporte e gestão global.

## Organização Do Monorepo

```text
apps/
  cliente/
  gestao/
packages/
  shared/
supabase/
  schema.sql
```

`apps/cliente` mantém a experiência rápida de agendamento. `apps/gestao` concentra as telas administrativas. `packages/shared` será o ponto comum para modelos, tema, cliente Supabase e regras de negócio compartilhadas.

## Próxima Fase Técnica

1. Mover modelos e tema comum para `packages/shared`.
2. Conectar Supabase Auth real.
3. Implementar repositórios reais com fallback mockado apenas em desenvolvimento.
4. Criar fluxo real de agendamento no App Cliente.
5. Criar painel real de agenda e serviços no App Gestão.
