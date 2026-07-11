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

- fundo preto puro `#000000`, conforme o storyboard aprovado;
- logo oficial colorida do Brand Kit V2, sem recriacao ou alteracao;
- roteiro de 2 segundos: fundo preto, risco amarelo, navalha, coroa,
  logo completa, slogan e fade out;
- navalha com escala e glow amarelo discreto;
- logo completa com fade e escala de 96% para 100%;
- carregamento inicial executado em paralelo com a animacao;
- destino definido pela conclusao previa do onboarding;
- largura responsiva e area segura para diferentes telas.
