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

Estado atual: o deploy do cliente não depende de variáveis do Supabase. O app
está rodando com dados mockados para manter a navegação e o visual estáveis
enquanto recriamos o banco do zero.

Quando o Supabase for reativado, cadastre estas variáveis em Project Settings >
Environment Variables:

```text
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anon-publica
```

Depois de salvar, faça um novo deploy para o app web receber a conexão real com
o Supabase.

## Supabase

Execute no SQL Editor:

```text
supabase/schema.sql
```

Depois que o schema rodar sem erro, rode os dados de exemplo:

```text
supabase/seed_demo.sql
```

Nao rode o `seed_demo.sql` antes do `schema.sql`, porque ele depende das tabelas ja criadas.

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

O app cliente está temporariamente desacoplado do Supabase. A próxima conexão
real deve ser feita com calma, usando o novo schema SaaS e fallback mockado
apenas para desenvolvimento.

## Próximos Passos

- Manter o App Cliente rápido, com foco em agendamento em poucos cliques.
- Evoluir `apps/gestao` como app separado para barbeiro, dono e equipe.
- Recriar o Supabase do zero com multiempresa por `barber_shop_id`.
- Conectar `supabase_flutter` somente depois do schema validado.
- Conectar Auth, agenda, serviços, equipe, caixa e relatórios no App Gestão.
