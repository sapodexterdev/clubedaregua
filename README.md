# Clube da Régua

SaaS para barbearias feito em Flutter, Dart e Supabase. A plataforma agora está organizada como monorepo com dois apps: um app rápido para clientes agendarem em poucos cliques e um app de gestão para barbeiros, donos e equipes administrarem agenda, serviços, clientes, caixa e operação.

## Apps

### App Cliente

Local: `apps/cliente`

Experiência mobile-first para o cliente:

- Buscar barbearia, barbeiro ou serviço.
- Escolher serviço, profissional, data e horário.
- Confirmar agendamento em poucos cliques.
- Acompanhar histórico, fidelidade, pagamentos e notificações.

Este é o app publicado hoje na Vercel.

### App Gestão

Local: `apps/gestao`

Experiência operacional para barbeiro, dono e equipe:

- Agenda do dia.
- Confirmação de atendimentos.
- Serviços, barbeiros e clientes.
- Bloqueio de horários, férias e indisponibilidade.
- Caixa, estoque, cupons, relatórios e assinatura SaaS.

### Pacote Compartilhado

Local: `packages/shared`

Código comum entre os apps:

- Cores da marca.
- Contexto da barbearia.
- Futuramente: modelos, cliente Supabase, tema, validações e regras comuns.

## Estrutura

```text
apps/
  cliente/
    lib/
    web/
    pubspec.yaml
  gestao/
    lib/
    pubspec.yaml
packages/
  shared/
    lib/
    pubspec.yaml
supabase/
  schema.sql
docs/
  arquitetura-saas.md
scripts/
  vercel-build.sh
```

## Visão SaaS

- Multiempresa desde o banco: cada barbearia é uma empresa isolada por `barber_shop_id`.
- Mesmo Supabase para Cliente e Gestão.
- Supabase Auth para identidade.
- Supabase Database com RLS por barbearia.
- Supabase Storage para fotos, logos e capas.
- Planos e assinaturas preparados no schema.

## Rodar Localmente

### Cliente

```bash
cd apps/cliente
flutter pub get
flutter run
```

### Gestão

```bash
cd apps/gestao
flutter pub get
flutter run
```

## Ambiente

Copie o exemplo de ambiente para o app que estiver rodando:

```bash
cp .env.example .env
```

Variáveis:

```text
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anon-pública
```

Também é possível rodar com `dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sua-chave-anon-pública
```

> Enquanto a conexão real com Supabase não estiver ativada no app, as telas usam dados mockados para permitir navegação e validação visual.

## Deploy Na Vercel

A Vercel publica o App Cliente:

```text
Build Command: bash scripts/vercel-build.sh
Output Directory: apps/cliente/build/web
Install Command: vazio
```

O script `scripts/vercel-build.sh` entra em `apps/cliente`, baixa o Flutter SDK, instala dependências e executa o build web.

Na Vercel, cadastre estas variáveis em Project Settings > Environment Variables:

```text
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anon-publica
```

Depois de salvar, faça um novo deploy para o app web receber a conexão real com o Supabase.

## Supabase

Execute no SQL Editor:

```text
supabase/schema.sql
```

O schema SaaS cria:

- users
- profiles
- plans
- subscriptions
- barber_shops
- shop_settings
- shop_members
- client_shop_relationships
- barbers
- services
- service_categories
- barber_services
- schedules
- blocked_times
- appointments
- payments
- reviews
- loyalty_points
- coupons
- notifications
- stock_items
- cash_movements

Também cria funções de autorização, policies de RLS por barbearia, índices básicos, planos iniciais e o bucket público `barbershop-media` para imagens.

O app cliente já usa Supabase quando essas variáveis estão configuradas:

- Supabase Auth para login e cadastro.
- Leitura real de barbeiros, categorias e serviços.
- Criação de agendamentos em `appointments`.
- Criação de pagamento PIX pendente em `payments`.
- Histórico real do cliente autenticado.
- Cancelamento de agendamento pelo cliente.

Se o banco ainda estiver vazio ou sem variáveis, o app mantém dados mockados para não quebrar a navegação visual.

## Próximos Passos

- Mover os modelos e o tema compartilhado do App Cliente para `packages/shared`.
- Remover telas de gestão que ainda ficaram dentro do App Cliente durante a transição.
- Conectar `supabase_flutter` no pacote compartilhado.
- Conectar Auth real no App Gestão.
- Conectar agenda, serviços e equipe no App Gestão.
