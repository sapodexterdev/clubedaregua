# UI-001 - Splash

## Objetivo

Documentar a especificacao visual final da tela Splash do app Cliente.

## Status

Implementada.

## Tela Relacionada

Splash Premium da Welcome Experience.

## Dependencias

- `docs/brand/Brand_Kit_v2.png`
- `docs/brand/BRAND_GUIDELINES.md`
- `docs/experience/welcome/`
- `docs/ux/UX-001-Primeiro-Acesso/`

## Observacoes

Esta tela deve apresentar a marca oficial com clareza, rapidez e impacto premium.

## Implementacao

- fundo radial entre `#18181B` e `#09090B`;
- logo oficial colorida do Brand Kit V2, sem recriacao ou alteracao;
- entrada com fade e escala de 98% para 100%;
- glow amarelo discreto;
- permanencia minima total de 2 segundos, incluindo fade out;
- carregamento inicial executado em paralelo com a animacao;
- destino definido pela conclusao previa do onboarding;
- largura responsiva e area segura para diferentes telas.
