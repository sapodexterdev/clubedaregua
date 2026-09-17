# UI-001 — Splash V3

## Objetivo

Definir a abertura institucional única do aplicativo Clube da Régua no Flutter
nativo e no boot Web/PWA.

## Status

**Aprovada — V3.**

## Tela Relacionada

Splash institucional que antecede Onboarding, Home pública, recuperação de
senha, convite de equipe ou o último modo profissional válido.

## Dependencias

- `docs/brand/ADR-001-V3-AUTORIDADE-VISUAL.md`
- `docs/brand/v3/BRAND_FOUNDATIONS.md`
- `docs/brand/v3/MOTION_SYSTEM.md`
- `docs/brand/BRAND_GUIDELINES.md`
- `docs/experience/welcome/`
- `docs/ux/UX-001-Primeiro-Acesso/`

## Observacoes

Esta tela apresenta a assinatura principal e o slogan oficiais uma única vez.
Ela não autentica novamente, não cria uma segunda sessão e não reaparece durante
a troca entre Cliente, Barbeiro e Dono.

## Fluxo

`Boot Web/PWA → decisão inicial única → destino`

No app nativo, a cena Flutter assume a apresentação. No Web/PWA, o HTML mantém
a mesma composição enquanto o runtime Flutter é carregado; a camada HTML só é
removida depois que o Flutter navega e entrega o primeiro frame do destino.

## Fonte normativa

A anatomia, o movimento, os estados lentos, a acessibilidade e os critérios de
aceite estão em [`spec.md`](spec.md).
