# Assets — UI-006 Home Pública

## Imagens das barbearias

Origem principal: capa cadastrada pela própria barbearia.

Regras:

- proporção obrigatória `16:9`;
- formatos aceitos no app: WebP, JPEG e PNG;
- carregamento com placeholder Grafite;
- erro ou URL vazia usa fallback local aprovado;
- não usar imagens aleatórias do Unsplash em produção;
- aplicar `cover` sem distorcer a imagem.

## Fallback de capa

Status: **pendente de aprovação**.

Nome previsto:

`apps/cliente/assets/images/barbershop_cover_fallback_v3.webp`

O fallback deve mostrar um interior de barbearia urbano premium, sem pessoas em
destaque, sem texto e sem marcas de terceiros.

## Ícones

- Material Symbols/Icons outline;
- tamanho padrão: `20–24 px`;
- espessura visual aproximada: `2 px`;
- Amarelo Régua apenas em seleção, ação e informação prioritária.

## Logo

Não exibir assinatura da marca no cabeçalho da Home. A navegação e o design
system já contextualizam o produto, preservando espaço para descoberta.

## Fontes

- Barlow Condensed: `600` e `700`;
- Inter: `400`, `500`, `600` e `700`;
- fontes empacotadas localmente no aplicativo.

## Proibições

- não usar `brand_logo_horizontal.png`;
- não usar navalha ou qualquer assinatura V2;
- não usar imagens remotas genéricas como fallback;
- não incorporar notas, textos, badges ou CTAs dentro das fotografias.
