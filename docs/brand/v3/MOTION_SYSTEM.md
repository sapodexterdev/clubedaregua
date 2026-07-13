# Clube da Régua — Sistema de Movimento V3

## Princípio

**Energia no gesto, precisão no repouso.**

As entradas podem carregar velocidade e personalidade urbana. Quando o
elemento chega à posição final, ele deve permanecer estável, nítido e sem
brilhos contínuos.

## Tokens

| Token | Duração | Uso |
| --- | --- | --- |
| Rápido | `150 ms` | toque, ripple, seleção e feedback imediato |
| Padrão | `250 ms` | troca de estado e entrada de elementos pequenos |
| Ênfase | `400 ms` | títulos, cards e elementos de marca |
| Cena | `2000 ms` | duração total máxima da Splash |

### Curvas

| Token | Curva | Uso |
| --- | --- | --- |
| Entrada | `cubic-bezier(0.16, 1, 0.3, 1)` | elementos chegando à tela |
| Padrão | `cubic-bezier(0.2, 0, 0, 1)` | transições gerais |
| Saída | `cubic-bezier(0.4, 0, 1, 1)` | elementos deixando a tela |
| Linear | `linear` | somente máscaras e desenho de traços |

Não usar `bounce` ou elasticidade em elementos da marca.

## Splash V3

### Duração total

`2000 ms`, incluindo a transição para a próxima tela.

### Sequência

| Tempo | Evento |
| --- | --- |
| `0–120 ms` | fundo Preto Marca `#050505`; pausa visual curta |
| `120–480 ms` | coroa aparece com máscara ascendente e escala `0.96 → 1` |
| `360–820 ms` | assinatura principal entra com máscara da esquerda para a direita |
| `640–980 ms` | sublinhado amarelo completa o gesto; brilho percorre uma única vez |
| `900–1200 ms` | marca estabiliza; todos os elementos ficam nítidos |
| `1120–1450 ms` | slogan entra por opacidade e deslocamento vertical de `6 px` |
| `1450–1760 ms` | pausa para leitura |
| `1760–2000 ms` | cena sai por fade; próxima tela entra sem flash branco |

### Composição

- fundo Preto Marca;
- assinatura principal centralizada;
- largura da marca: `76%` da tela, limitada entre `260–420 px`;
- slogan a `24 px` abaixo da área visual da marca;
- respeitar `24 px` de margem lateral e a `SafeArea`;
- em tablet/web, limitar o conjunto a `480 px` de largura.

### Brilho

O brilho é um reflexo estreito e rápido aplicado somente ao sublinhado amarelo.

- duração: `260 ms`;
- opacidade máxima: `0.28`;
- desfoque máximo: `8 px`;
- executar uma única vez;
- não aplicar glow contínuo na logo ou na coroa.

### Slogan

`O SISTEMA FEITO PARA BARBEARIAS.`

- Inter `700`, `11 px`, caixa alta;
- tracking `2.2 px`;
- texto branco; `BARBEARIAS.` em Amarelo Régua;
- não incorporar o slogan ao SVG da assinatura.

### Regras

- não usar navalha na Splash V3;
- não desmontar o nome letra por letra;
- não girar, inclinar ou deformar a assinatura;
- não fazer a coroa desaparecer antes da marca completa;
- não repetir a animação enquanto dados estiverem carregando;
- se o carregamento ultrapassar `2000 ms`, manter a marca estática e exibir um
  indicador discreto separado.

## Transição para onboarding ou home

- Splash: fade `1 → 0` em `240 ms`;
- destino: fade `0 → 1` e deslocamento `8 → 0 px` em `320 ms`;
- sobreposição entre cenas: `120 ms`;
- manter o mesmo fundo durante a sobreposição para evitar cintilação.

## Onboarding

### Troca de páginas

- imagem: parallax máximo de `16 px`;
- título: fade + deslocamento vertical de `8 px`, `300 ms`;
- corpo: fade, `250 ms`, com atraso de `40 ms`;
- CTA: permanece estável; somente o rótulo pode mudar por crossfade;
- indicador: cápsula muda de largura em `250 ms`.

### CTA principal

- pressionar: escala `1 → 0.98`, `100 ms`;
- soltar: escala `0.98 → 1`, `150 ms`;
- ripple Amarelo Régua com contraste sobre o botão;
- não usar pulso automático contínuo.

## Home

- saudação: fade + `8 px` de baixo para cima, `300 ms`;
- busca: fade, atraso de `40 ms`;
- seções: entrada progressiva com intervalo máximo de `60 ms`;
- cards: deslocamento máximo de `12 px`; nunca animar todos individualmente em
  listas longas.

## Acessibilidade

Quando `disableAnimations` ou redução de movimento estiver ativa:

- remover máscaras, parallax, escala e deslocamentos;
- usar apenas fade de `150–250 ms`;
- Splash: marca completa entra em `200 ms`, permanece estática e sai em
  `150 ms`;
- navegação e carregamento não podem depender do término de animações
  decorativas.

## Critérios de aceite

- duração da Splash não excede `2000 ms`;
- nenhuma navalha ou ativo V2 aparece;
- logo final coincide com o SVG oficial da V3;
- animação permanece fluida em `60 fps` em aparelho intermediário;
- não há flash branco entre Splash e destino;
- redução de movimento é respeitada;
- o carregamento de dados acontece em paralelo à animação.

