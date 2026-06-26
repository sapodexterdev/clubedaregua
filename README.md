# Clube da Régua

SaaS para barbearias feito em Flutter, Dart e Supabase. A plataforma terá dois produtos conectados ao mesmo backend: um app rápido para clientes agendarem em poucos cliques e um app de gestão para barbeiros, donos e equipes administrarem agenda, serviços, clientes, caixa e operação.

## Visão SaaS

- Multiempresa desde o banco: cada barbearia é uma empresa isolada por `barber_shop_id`.
- App Cliente focado em velocidade: buscar, escolher serviço, escolher horário e confirmar.
- App Barbeiro/Dono focado em gestão: agenda, equipe, serviços, relatórios, caixa, cupons, estoque e assinatura.
- Supabase Auth para identidade.
- Supabase Database com RLS por barbearia.
- Supabase Storage para fotos, logos e capas.
- Planos e assinaturas preparados no schema.

## Stack

- Flutter
- Dart
- Supabase Auth
- Supabase Database
- Supabase Storage
- Provider para estado
- Arquitetura organizada por camadas

## Estrutura Atual

```text
lib/
  app.dart
  main.dart
  config/
  core/
  models/
  providers/
  repositories/
  screens/
    admin/
    auth/
    barber/
    client/
  services/
  theme/
  widgets/
supabase/
  schema.sql
docs/
  arquitetura-saas.md
```

## Separação Dos Apps

O repositório ainda está em um app Flutter único para acelerar o protótipo visual. A direção do produto é separar em:

- `App Cliente`: experiência simples, rápida e mobile-first para agendamento.
- `App Gestão`: experiência completa para barbeiro, dono e equipe.
- `Shared`: modelos, tema, cliente Supabase e regras comuns.

Estrutura recomendada para a próxima fase:

```text
apps/
  cliente/
  gestao/
packages/
  shared/
supabase/
  schema.sql
```

## Telas Incluídas

- Splash
- Onboarding
- Login
- Cadastro
- Home Cliente
- Detalhes do Barbeiro
- Agendamento
- Confirmação de Agendamento
- Histórico
- Perfil Cliente
- Painel do Barbeiro
- Agenda Barbeiro
- Painel do Administrador
- Cadastro de Serviços
- Cadastro de Barbeiros

## Configuração Local

1. Instale o Flutter SDK.
2. Entre na pasta do projeto:

```bash
cd clubedaregua
```

3. Gere as plataformas Flutter, caso ainda não existam:

```bash
flutter create .
```

4. Instale as dependências:

```bash
flutter pub get
```

5. Copie o arquivo de ambiente:

```bash
cp .env.example .env
```

6. Preencha as variáveis:

```text
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anon-pública
```

7. Rode o app:

```bash
flutter run
```

Ou rode informando as credenciais por `dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sua-chave-anon-pública
```

> Enquanto a conexão real com Supabase não estiver ativada no app, as telas usam dados mockados para permitir navegação e validação visual.

## Deploy Na Vercel

Este projeto está preparado para rodar como Flutter Web na Vercel. A Vercel executa `scripts/vercel-build.sh`, baixa o Flutter SDK, instala dependências e publica `build/web`.

1. Importe o repositório `sapodexterdev/clubedaregua` na Vercel.
2. Configure o projeto como `Other`.
3. Confirme os campos:

```text
Build Command: bash scripts/vercel-build.sh
Output Directory: build/web
Install Command: vazio
```

4. Adicione as variáveis de ambiente:

```text
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anon-pública
```

5. Clique em Deploy.

O arquivo `vercel.json` configura rewrite para `index.html`, necessário para navegação SPA.

## Supabase

1. Crie um projeto no Supabase.
2. Abra o SQL Editor.
3. Execute o arquivo:

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

## Fluxos Principais

### Cliente

- Onboarding com imagem grande e CTA.
- Login/cadastro via Supabase Auth.
- Busca por barbearia, serviço ou barbeiro.
- Agendamento em poucos cliques: serviço, profissional, data, horário e confirmação.
- PIX, histórico, cancelamento, avaliação, fidelidade e notificações.

### Barbeiro

- Login como barbeiro.
- Painel com agenda do dia, atendimentos e comissão.
- Confirmação de atendimentos.
- Bloqueio de horários, férias e indisponibilidade.
- Visualização de clientes e próximos retornos.

### Dono/Administrador

- Painel administrativo.
- Cadastro de barbeiros e serviços.
- Controle de agenda.
- Relatórios de faturamento e ranking.
- Serviços mais vendidos.
- Caixa, cupons, estoque e configurações da barbearia.
- Gestão do plano SaaS e assinatura.

## Próximos Passos Sugeridos

- Separar o monorepo em `apps/cliente`, `apps/gestao` e `packages/shared`.
- Ativar `supabase_flutter` e conectar Auth real.
- Conectar listagem pública de barbearias, barbeiros, serviços e horários.
- Implementar criação real de agendamento.
- Conectar painel de gestão ao banco com RLS por barbearia.
- Integrar provedor de PIX real.
