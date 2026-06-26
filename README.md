# Clube da Régua

Aplicativo mobile de barbearia feito em Flutter, Dart e Supabase. A proposta visual é inspirada em apps modernos de agendamento: fundo claro, fotos grandes, cards brancos arredondados, botões laranja e navegação inferior escura.

## Stack

- Flutter
- Dart
- Supabase Auth
- Supabase Database
- Supabase Storage
- Provider para estado
- Arquitetura organizada por camadas

## Estrutura

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
```

## Telas incluídas

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

## Configuração local

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

> Enquanto o Supabase não estiver configurado, o app usa dados mockados para permitir navegar pelas telas.

## Deploy na Vercel

Este projeto também está preparado para rodar como Flutter Web na Vercel. A Vercel executa `scripts/vercel-build.sh`, baixa o Flutter SDK, instala dependências e publica `build/web`.

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

O arquivo `vercel.json` também configura rewrite para `index.html`, necessário para navegação SPA.

## Supabase

1. Crie um projeto no Supabase.
2. Abra o SQL Editor.
3. Execute o arquivo:

```text
supabase/schema.sql
```

O schema cria:

- users
- profiles
- barbers
- barber_shops
- services
- service_categories
- appointments
- reviews
- payments
- loyalty_points
- coupons
- schedules
- blocked_times
- notifications
- stock_items
- cash_movements

Também cria policies iniciais de RLS, índices básicos e o bucket público `barbershop-media` para imagens.

## Fluxos principais

### Cliente

- Onboarding com imagem grande e CTA.
- Login/cadastro via Supabase Auth.
- Home com saudação, busca, filtro, banner promocional, categorias, barbeiros e serviços.
- Detalhe do barbeiro com foto grande, favorito, avaliação, abas, calendário, horários e resumo.
- Agendamento com serviço, data, horário, PIX e status.
- Histórico, cancelamento visual, avaliação e fidelidade com pontos.
- Notificações internas no perfil.

### Barbeiro

- Login como barbeiro.
- Painel com agenda do dia, atendimentos e comissão.
- Agenda com bloqueio/liberação de horários.
- Entradas iniciais para clientes, férias e indisponibilidade.

### Administrador

- Painel administrativo.
- Cadastro de barbeiros e serviços.
- Controle de agenda.
- Relatório simples de faturamento.
- Ranking de barbeiros.
- Serviços mais vendidos.
- Caixa, cupons e estoque básico.

## Próximos passos sugeridos

- Conectar formulários admin aos repositories.
- Implementar upload real de fotos no Supabase Storage.
- Criar policies de admin/owner mais granulares.
- Adicionar testes de widgets para home, login e agendamento.
- Integrar provedor de PIX real.
