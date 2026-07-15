# Spec — UI-003 Onboarding 02

## Status

Aprovada para implementação.

## Objetivo

Mostrar que o agendamento é simples e rápido: o usuário escolhe serviço,
profissional e horário sem burocracia. Esta é a segunda etapa do fluxo e deve
dar continuidade visual ao Onboarding 01 sem repetir sua fotografia.

## Conteúdo oficial

- **Título:** `Agende seu horário em poucos segundos.`
- **Texto de apoio:** `Escolha o serviço, o profissional e o melhor horário para você.`
- **CTA principal:** `CONTINUAR`
- **Ação secundária:** `Pular`
- **Acessibilidade do indicador:** `Etapa 2 de 3`

## Composição

1. fotografia vertical de uma barbearia premium ao fundo;
2. camada escura para contraste;
3. botão `Pular` no canto superior direito;
4. ícone outline de calendário em Amarelo Régua;
5. título e texto centralizados;
6. prévia compacta de horários disponíveis;
7. CTA fixo e indicador de três etapas.

### Fotografia

- interior de barbearia urbana, moderna e organizada;
- cadeira premium preparada para o próximo atendimento;
- espelho, bancada e iluminação quente compondo profundidade;
- sem pessoas em destaque, para diferenciar do Onboarding 01;
- área inferior escura e com pouco detalhe para receber a interface;
- formato mestre recomendado: `1440 × 2560 px`.

### Camada de contraste

- topo: Preto Marca com `38%` de opacidade;
- centro: Noite com `52%` de opacidade;
- base: Noite com `94%` de opacidade.

## Tipografia

| Elemento | Fonte | Tamanho/linha | Peso | Cor |
| --- | --- | --- | --- | --- |
| Título | Barlow Condensed | `32/36` | `700` | Branco |
| Corpo | Inter | `14/20` | `400` | Texto secundário |
| Horário | Inter | `13/18` | `600` | Branco/Noite |
| CTA | Inter | `14/18` | `700` | Noite |
| Pular | Inter | `14/18` | `600` | Branco |

## Cores

- Preto Marca: `#050505`;
- Noite: `#09090B`;
- Grafite: `#18181B`;
- Borda: `#3F3F46`;
- Amarelo Régua: `#F3B200`;
- Amarelo pressionado: `#D99F00`;
- Branco: `#FFFFFF`;
- Texto secundário: `#A1A1AA`.

## Espaçamento

- margem lateral: `24 px`;
- ícone → título: `20 px`;
- título → corpo: `12 px`;
- corpo → horários: `24 px`;
- espaço entre horários: `8 px`;
- horários: altura `40 px`, raio `8 px`;
- horários → CTA: mínimo `32 px`;
- CTA: altura `56 px`, raio `14 px`;
- CTA → indicador: `20 px`.

## Ícone

Usar calendário outline com traço visual de `2 px`, tamanho `40 px` e cor
Amarelo Régua. Não usar emoji, coroa, navalha, logo ou medalhão circular.

## Prévia de horários

Exibir três opções compactas em linha:

- `09:00` — inativa;
- `10:30` — inativa;
- `15:00` — selecionada.

As opções são demonstrativas e não devem abrir o agendamento nesta etapa.

### Estados

- inativo: fundo Grafite, texto branco e borda `#3F3F46`;
- selecionado: fundo Amarelo Régua, texto Noite e sem sombra;
- nenhuma opção pode pulsar ou produzir brilho contínuo.

## CTA e navegação

- `CONTINUAR` avança para Explorar Barbearias;
- swipe horizontal permite avançar ou retornar;
- `Pular` avança diretamente para Explorar Barbearias;
- o onboarding somente é concluído na tela seguinte;
- CTA permanece estável durante a troca da página.

## Movimento

- troca de página: `300 ms`, curva padrão V3;
- fotografia: parallax horizontal máximo de `16 px`;
- ícone e título: fade + deslocamento `8 → 0 px` em `300 ms`;
- corpo: fade de `250 ms`, atraso de `40 ms`;
- horários: fade de `250 ms`, atraso de `80 ms`;
- indicador: cápsula muda de largura em `250 ms`;
- não usar bounce, glow, rotação ou pulso automático.

Com redução de movimento ativa, usar somente fade de `200 ms`.

## Responsividade

### Mobile

- tela cheia, respeitando SafeArea;
- fotografia em `cover` com ponto focal central;
- horários permanecem em uma única linha até `360 px` de largura;
- em telas menores, reduzir padding horizontal dos horários sem reduzir texto.

### Tablet e web

- apresentar dentro do frame do aplicativo;
- largura máxima do conteúdo: `430 px`;
- não esticar fotografia, horários ou CTA pela largura do navegador.

## Critérios de aceite

- usa somente tokens e tipografia V3;
- não exibe logo, coroa, navalha ou qualquer ativo V2;
- texto está acentuado corretamente;
- fotografia é local e não depende de URL externa;
- horários possuem contraste e seleção legíveis;
- `CONTINUAR` e `Pular` levam para Explorar Barbearias;
- conteúdo permanece íntegro em `360 × 640 px`;
- redução de movimento é respeitada;
- nenhuma conta é exigida.
