# Spec — UI-004 Onboarding 03

## Status

Aprovada para implementação V3.

## Objetivo

Encerrar o onboarding deixando explícito que o Cliente pode explorar
barbearias, serviços, profissionais e avaliações antes de criar uma conta.

## Conteúdo oficial

- **Título:** `Explore barbearias no seu ritmo.`
- **Texto:** `Conheça serviços, profissionais e avaliações antes de criar sua conta.`
- **CTA:** `EXPLORAR BARBEARIAS`
- **Indicador acessível:** `Etapa 3 de 3`

## Composição

- fundo Noite `#09090B`, sem fotografia remota;
- assinatura principal V3 centralizada, sem navalha ou ativo V2;
- título Barlow Condensed `32/36`, peso `700`;
- corpo Inter `14/20`, peso `400`;
- CTA de `56 px`, raio `14 px`, Amarelo Régua e texto Noite;
- margem lateral `24 px` e SafeArea obrigatória;
- indicador de três etapas abaixo do CTA.

## Comportamento

- `CONTINUAR` da etapa 2 abre esta etapa;
- `Pular` nas etapas 1 ou 2 abre esta etapa, sem concluir o onboarding;
- o CTA final grava a preferência de onboarding uma única vez, mantém o modo
  Cliente e substitui a rota pela Home Pública;
- não exige login e não executa bootstrap, Splash ou listener de autenticação;
- swipe horizontal permite retornar às etapas anteriores.

## Movimento e acessibilidade

- não existe autoplay, timer periódico, pulso ou loop;
- troca programática: `300 ms`, curva V3;
- com redução de movimento, usar mudança imediata e indicador sem animação;
- CTA final deve impedir submissões duplicadas;
- alvos de toque têm no mínimo `44 px` e o indicador anuncia etapa e total.

## Responsividade

- conteúdo rolável quando necessário, sem ficar atrás do rodapé;
- íntegro em `360 × 640`, `390 × 844` e texto a `200%`;
- Cliente permanece dentro do frame máximo de `430 px` no tablet/web;
- nenhum recurso de rede é necessário para renderizar a etapa.

## Critérios de aceite

- exatamente três etapas no indicador;
- somente ativos locais V3;
- `Pular` não marca onboarding como visto;
- dois toques rápidos no CTA final geram uma única navegação;
- segunda abertura do app não reapresenta o onboarding;
- sessão Supabase e último modo profissional não são inicializados novamente.
