# UI-002 — Onboarding 01

## Objetivo

Apresentar a descoberta de barbearias como o primeiro benefício do Clube da
Régua após a Splash V3.

## Status

Aprovada.

## Posição no fluxo

`Splash → Onboarding 01 → Onboarding 02 → Explorar Barbearias → Home Pública`

## Fonte de verdade

Esta especificação atualiza a tela para a Brand V3. Em caso de divergência com
boards antigos, prevalecem:

1. `docs/brand/v3/BRAND_FOUNDATIONS.md`;
2. `docs/brand/v3/MOTION_SYSTEM.md`;
3. `spec.md` desta tela;
4. `docs/ux/UX-001-Primeiro-Acesso/` para regras funcionais do fluxo.

Boards que contenham navalha, logo V2, Bebas Neue ou dourado antigo são apenas
referências históricas de composição e não devem fornecer ativos para o app.

## Dependências

- fotografia vertical aprovada `onboarding_v3_descobrir.webp`;
- Barlow Condensed e Inter configuradas no aplicativo;
- componente de CTA V3;
- ícone outline de localização;
- indicador de três etapas.

## Regra de implementação

A tela só deve ser implementada depois da aprovação do conteúdo e da direção
visual. Alterações futuras precisam atualizar esta documentação no mesmo PR.

## Revisão no preview web

Em produção, o onboarding aparece apenas na primeira utilização. Para revisar
o fluxo repetidamente na prévia web, acrescentar `?preview=onboarding` à URL.
Esse parâmetro não altera a preferência salva nem o comportamento normal do
aplicativo.
