# Spec — UI-002 Onboarding 01

## Status

Aprovada para implementação.

## Objetivo

Comunicar, logo após a Splash, que o usuário pode encontrar boas barbearias
próximas sem criar uma conta. A tela deve parecer urbana e premium, com leitura
rápida e uma única ação principal.

## Conteúdo oficial

- **Título:** `Encontre as melhores barbearias perto de você.`
- **Texto de apoio:** `Avaliações reais, horários disponíveis e tudo o que você precisa para escolher bem.`
- **CTA principal:** `CONTINUAR`
- **Ação secundária:** `Pular`
- **Acessibilidade do indicador:** `Etapa 1 de 3`

Não usar textos sem acentuação nem escrever o nome da marca com fonte de
sistema.

## Composição

1. fotografia vertical em tela cheia;
2. camada escura para garantir contraste;
3. botão `Pular` no canto superior direito;
4. ícone outline de localização em Amarelo Régua;
5. título e texto centralizados no terço inferior;
6. CTA principal fixo acima da SafeArea;
7. indicador de três etapas abaixo do CTA.

### Fotografia

- barbearia urbana contemporânea e bem decorada;
- atendimento real, humano e profissional;
- luz quente, acabamento cinematográfico e predominância escura;
- sem textos, logos de terceiros ou objetos cortados de forma artificial;
- preservar área visual limpa no terço inferior para o conteúdo;
- formato mestre recomendado: `1440 × 2560 px`.

### Camada de contraste

Aplicar gradiente vertical sobre a fotografia:

- topo: Preto Marca com `36%` de opacidade;
- centro: Noite com `48%` de opacidade;
- base: Noite com `94%` de opacidade.

Não aplicar desfoque permanente nem glow sobre a fotografia.

## Tipografia

| Elemento | Fonte | Tamanho/linha | Peso | Cor |
| --- | --- | --- | --- | --- |
| Título | Barlow Condensed | `32/36` | `700` | Branco |
| Corpo | Inter | `14/20` | `400` | Texto secundário |
| CTA | Inter | `14/18` | `700` | Noite |
| Pular | Inter | `14/18` | `600` | Branco |

O título deve ocupar no máximo três linhas em telas móveis de `360 px`.

## Cores

- Preto Marca: `#050505`;
- Noite: `#09090B`;
- Amarelo Régua: `#F3B200`;
- Branco: `#FFFFFF`;
- Texto secundário: `#A1A1AA`;
- Indicador inativo: `#3F3F46`.

## Espaçamento

- margem lateral: `24 px`;
- área segura superior e inferior obrigatória;
- distância ícone → título: `20 px`;
- distância título → corpo: `12 px`;
- distância corpo → CTA: `32 px`;
- altura do CTA: `56 px`;
- raio do CTA: `14 px`;
- distância CTA → indicador: `20 px`.

## Ícone

Usar ícone outline de localização, com traço de `2 px`, tamanho `40 px` e cor
Amarelo Régua. Não usar navalha, logo V2 ou emoji.

## CTA e navegação

- `CONTINUAR` avança para o Onboarding 02;
- swipe horizontal também avança ou retorna;
- `Pular` leva diretamente para a tela Explorar Barbearias;
- tocar no indicador não muda a página;
- o CTA não deve finalizar o onboarding na primeira tela.

### Estados do CTA

- padrão: fundo Amarelo Régua e texto Noite;
- pressionado: Amarelo pressionado `#D99F00` e escala `0.98`;
- foco por teclado: contorno branco de `2 px` com afastamento de `2 px`;
- desabilitado: não previsto nesta tela.

## Movimento

- troca de página: `300 ms`, curva padrão V3;
- fotografia: parallax horizontal máximo de `16 px`;
- ícone e título: fade + deslocamento vertical `8 → 0 px` em `300 ms`;
- corpo: fade em `250 ms`, atraso de `40 ms`;
- indicador ativo: largura `24 px`, transição de `250 ms`;
- CTA permanece estável durante a troca de páginas;
- não usar pulso automático, bounce ou brilho contínuo.

Com redução de movimento ativa, remover parallax, escala e deslocamentos e usar
somente fade de `200 ms`.

## Responsividade

### Mobile

- ocupa toda a viewport;
- conteúdo respeita SafeArea e largura máxima disponível;
- fotografia usa `cover`, com ponto focal configurável.

### Tablet e web

- apresentar dentro do frame do aplicativo;
- largura máxima do conteúdo: `430 px`;
- manter a mesma hierarquia e proporções da versão mobile;
- não esticar título, botão ou fotografia pela largura do navegador.

## Critérios de aceite

- utiliza exclusivamente tokens e tipografia V3;
- não exibe navalha nem qualquer ativo V2;
- título e texto estão acentuados corretamente;
- CTA avança para o Onboarding 02;
- `Pular` leva para Explorar Barbearias;
- imagem não aparece cortada horizontalmente ou carregada em faixas;
- conteúdo permanece legível em `360 × 640 px`;
- transição funciona com fluidez e respeita redução de movimento;
- nenhuma conta é exigida durante o fluxo.
