# Clube da Regua

Aplicativo mobile de barbearia feito em Flutter, Dart e Supabase. A proposta visual e inspirada em apps modernos de agendamento: fundo claro, fotos grandes, cards brancos arredondados, botoes laranja e navegacao inferior escura.

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

## Telas incluidas

- Splash
- Onboarding
- Login
- Cadastro
- Home Cliente
- Detalhes do Barbeiro
- Agendamento
- Confirmacao de Agendamento
- Historico
- Perfil Cliente
- Dashboard Barbeiro
- Agenda Barbeiro
- Dashboard Admin
- Cadastro de Servicos
- Cadastro de Barbeiros

## Configuracao local

1. Instale o Flutter SDK.
2. Entre na pasta do projeto:

```bash
cd clubedaregua
```

3. Gere as plataformas Flutter, caso ainda nao existam:

```bash
flutter create .
```

4. Instale as dependencias:

```bash
flutter pub get
```

5. Copie o arquivo de ambiente:

```bash
cp .env.example .env
```

6. Preencha as variaveis:

```text
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anon-publica
```

7. Rode o app:

```bash
flutter run
```

Ou rode informando as credenciais por `dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sua-chave-anon-publica
```

> Enquanto o Supabase nao estiver configurado, o app usa dados mockados para permitir navegar pelas telas.

## Deploy na Vercel

Este projeto tambem esta preparado para rodar como Flutter Web na Vercel. A Vercel executa `scripts/vercel-build.sh`, baixa o Flutter SDK, instala dependencias e publica `build/web`.

1. Importe o repositorio `sapodexterdev/clubedaregua` na Vercel.
2. Configure o projeto como `Other`.
3. Confirme os campos:

```text
Build Command: bash scripts/vercel-build.sh
Output Directory: build/web
Install Command: vazio
```

4. Adicione as variaveis de ambiente:

```text
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anon-publica
```

5. Clique em Deploy.

O arquivo `vercel.json` tambem configura rewrite para `index.html`, necessario para navegacao SPA.

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

Tambem cria policies iniciais de RLS, indices basicos e o bucket publico `barbershop-media` para imagens.

## Fluxos principais

### Cliente

- Onboarding com imagem grande e CTA.
- Login/cadastro via Supabase Auth.
- Home com saudacao, busca, filtro, banner promocional, categorias, barbeiros e servicos.
- Detalhe do barbeiro com foto grande, favorito, avaliacao, abas, calendario, horarios e resumo.
- Agendamento com servico, data, horario, PIX e status.
- Historico, cancelamento visual, avaliacao e fidelidade com pontos.
- Notificacoes internas no perfil.

### Barbeiro

- Login como barbeiro.
- Dashboard com agenda do dia, atendimentos e comissao.
- Agenda com bloqueio/liberacao de horarios.
- Entradas iniciais para clientes, ferias e indisponibilidade.

### Admin

- Dashboard administrativo.
- Cadastro de barbeiros e servicos.
- Controle de agenda.
- Relatorio simples de faturamento.
- Ranking de barbeiros.
- Servicos mais vendidos.
- Caixa, cupons e estoque basico.

## Proximos passos sugeridos

- Conectar formularios admin aos repositories.
- Implementar upload real de fotos no Supabase Storage.
- Criar policies de admin/owner mais granulares.
- Adicionar testes de widgets para home, login e agendamento.
- Integrar provedor de PIX real.
