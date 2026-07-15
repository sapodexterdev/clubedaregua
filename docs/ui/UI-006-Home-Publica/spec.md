# Spec — UI-006 Home Pública

## Status

Aprovada para implementação por blocos.

## Objetivo

Permitir que qualquer pessoa descubra, pesquise e compare barbearias sem criar
uma conta. A Home deve priorizar localização, busca, confiança e acesso rápido
ao perfil e aos horários disponíveis.

## Hierarquia da tela

1. saudação e notificações;
2. pergunta principal;
3. busca;
4. localização e filtros;
5. categorias;
6. barbearia em destaque;
7. próximos horários;
8. barbearias perto de você;
9. navegação inferior.

## Cabeçalho

### Saudação

- autenticado: `Olá, {primeiro nome}!`;
- visitante: `Olá!`;
- não usar nome fixo no código;
- texto secundário Inter `13/18`, peso `500`, cor `#A1A1AA`.

### Pergunta principal

`Onde você quer dar aquela renovada hoje?`

- Barlow Condensed `32/36`, peso `700`;
- branco;
- máximo de três linhas em `360 px`;
- alinhamento à esquerda.

### Notificações

- botão circular de `44 px`;
- fundo Grafite, borda `#3F3F46`;
- sino outline de `22 px`;
- visitantes podem abrir a central pública, sem exigir login apenas pelo toque.

## Busca

- placeholder: `Buscar barbearias, serviços...`;
- altura: `52 px`;
- fundo Grafite;
- raio: `14 px`;
- ícone de busca à esquerda;
- botão de filtros à direita, com área de toque mínima de `44 px`;
- busca filtra por nome da barbearia, serviço e bairro;
- busca ignora diferenças entre letras acentuadas e não acentuadas;
- enquanto houver texto, substituir as seções repetidas por uma lista única de
  resultados encontrados;
- aplicar atraso de `250 ms` antes de consultar o backend.

## Localização

- linha abaixo da busca;
- ícone outline amarelo;
- texto dinâmico `{cidade}, {UF}`;
- visitante sem permissão: `Definir localização`;
- toque abre seletor de localização;
- a permissão do dispositivo só deve ser solicitada após o toque em
  `Usar minha localização`;
- quando autorizada, considerar apenas barbearias com coordenadas confirmadas
  em um raio inicial de `10 km`;
- calcular e exibir a distância real entre o dispositivo e a barbearia;
- não persistir as coordenadas precisas do visitante;
- se a permissão for negada ou a localização falhar, manter a seleção manual
  de cidade disponível;
- barbearias sem latitude e longitude não entram no resultado por proximidade;
- nunca fixar `Uberaba, MG` como localização universal.

## Categorias

Ordem inicial:

1. Corte;
2. Barba;
3. Combo;
4. Infantil;
5. Premium.

### Chips

- altura mínima `44 px`;
- fundo Grafite;
- borda `#3F3F46`;
- raio Pílula;
- ícone outline + label Inter `12/16`, peso `600`;
- selecionado: borda e ícone em Amarelo Régua;
- permitir rolagem horizontal sem cortar o primeiro ou último chip.

## Seções

### Mais bem avaliadas

- primeiro bloco de conteúdo;
- exibir uma barbearia em card grande;
- cabeçalho com `Ver todas`;
- `Ver todas` abre uma listagem completa e navegável da seção;
- ícone de estrela outline, sem usar fogo genérico em todas as seções.

### Próximos horários

- cards horizontais compactos;
- mostrar nome, nota, distância, status e próximo horário;
- ordenar pelo horário disponível mais próximo;
- título completo: `Próximos horários disponíveis`.

### Perto de você

- cards grandes ou lista vertical;
- ordenar por distância quando a localização estiver disponível;
- sem localização, ocultar a seção e apresentar ação para definir cidade.

Não exibir seções duplicadas quando todas contiverem exatamente as mesmas
barbearias.

## Card grande de barbearia

### Estrutura

- superfície Grafite, raio `14 px`, borda `#3F3F46`;
- imagem obrigatoriamente `16:9`;
- nome;
- nota e quantidade de avaliações;
- distância;
- status `Aberto agora` ou `Fechado`;
- fechamento ou próximo horário;
- faixa de preço;
- CTA `Ver horários`.

### Imagem

- usar URL da própria barbearia;
- fallback local aprovado quando a URL estiver vazia ou falhar;
- `cover`, sem distorção;
- placeholder escuro durante carregamento;
- não depender do Unsplash em produção.

### CDR Score

- badge de `52 × 52 px` sobre a imagem;
- fundo Noite com `92%` de opacidade;
- borda Amarelo Régua;
- nota em Barlow Condensed `20/22`, peso `700`;
- legenda `CDR SCORE` em Inter `8/10`, peso `700`;
- exibir apenas quando houver base mínima de avaliações definida pelo produto;
- caso contrário, usar somente avaliação por estrelas.

## Card compacto

- largura entre `260–286 px`;
- nome, nota, distância, status e próximo horário sempre visíveis;
- área inteira abre o perfil;
- sem botão adicional dentro do card;
- não usar o badge como única representação da barbearia.

## Navegação inferior

Itens:

1. Descobrir;
2. Favoritos;
3. Agenda;
4. Perfil.

- altura `72 px` + SafeArea;
- fundo Noite e borda superior;
- item ativo em Amarelo Régua;
- item inativo em Texto secundário;
- ícones outline de `22–24 px`;
- visitante pode navegar em Descobrir;
- Favoritos, Agenda e Perfil solicitam autenticação somente quando acessados;
- preservar o destino solicitado após o login.

## Estados

### Carregando

- skeletons com a mesma geometria dos cards;
- não mostrar apenas um spinner em uma grande área vazia;
- animação discreta, respeitando redução de movimento.

### Vazio

- título: `Nenhuma barbearia encontrada.`;
- apoio: `Tente alterar a busca, os filtros ou a localização.`;
- CTA secundário: `Limpar filtros`;
- ícone outline neutro.

### Erro

- título: `Não foi possível carregar as barbearias.`;
- apoio: `Verifique sua conexão e tente novamente.`;
- CTA: `Tentar novamente`;
- nunca exibir mensagem técnica ao usuário.

## Tipografia

| Elemento | Fonte | Tamanho/linha | Peso |
| --- | --- | --- | --- |
| Pergunta principal | Barlow Condensed | `32/36` | `700` |
| Título de seção | Barlow Condensed | `22/26` | `700` |
| Nome da barbearia | Inter | `16/22` | `700` |
| Corpo | Inter | `14/20` | `400` |
| Label | Inter | `12–14/16–18` | `600` |
| Legenda | Inter | `11/14` | `500` |

## Cores e superfícies

- fundo: Noite `#09090B`;
- cards e campos: Grafite `#18181B`;
- elevado: `#27272A`;
- borda: `#3F3F46`;
- ação/destaque: Amarelo Régua `#F3B200`;
- texto: Branco `#FFFFFF`;
- secundário: `#A1A1AA`;
- aberto: Sucesso `#22C55E`;
- erro: `#EF4444`.

## Espaçamento

- margem lateral mobile: `24 px`;
- grade-base: `4 px`;
- cabeçalho → busca: `24 px`;
- busca → localização: `12 px`;
- localização → categorias: `20 px`;
- categorias → primeira seção: `24 px`;
- entre seções: `32 px`;
- padding interno de cards: `12–16 px`.

## Movimento

- entrada do cabeçalho: fade + `8 → 0 px`, `300 ms`;
- busca: fade com atraso de `40 ms`;
- seções: entrada progressiva, intervalo máximo `60 ms`;
- card pressionado: escala `1 → 0.99`, `100 ms`;
- filtro: painel inferior com transição padrão de `300 ms`;
- favoritar: preenchimento de ícone em `250 ms`;
- não animar individualmente listas longas;
- com redução de movimento, usar somente fades de `150–200 ms`.

## Responsividade

### Mobile

- layout de coluna única;
- conteúdo respeita SafeArea;
- cards grandes ocupam a largura disponível;
- listas compactas usam rolagem horizontal.

### Tablet e web

- largura máxima da experiência: `430 px` enquanto o produto estiver no modo
  mobile-first;
- centralizar o frame no navegador;
- não esticar cards e seções pela tela inteira;
- manter navegação inferior dentro do frame.

## Regras funcionais

- exploração, busca, filtros e perfil são públicos;
- login é solicitado apenas para favoritar ou iniciar agendamento;
- abrir perfil exige uma única ação;
- horários devem ser alcançados em até dois toques;
- todos os textos devem estar acentuados;
- localização, saudação e resultados vêm do estado do aplicativo;
- não usar dados fixos para simular personalização em produção.

## Critérios de aceite

- usa exclusivamente tokens e linguagem V3;
- não exibe navalha, logo V2 ou fontes antigas;
- visitante consegue pesquisar e abrir uma barbearia sem login;
- saudação e localização não são fixas;
- imagens mantêm `16:9` e possuem fallback local;
- busca, filtros, cards e estados têm funcionamento real;
- cards mostram informações essenciais sem truncamento crítico;
- navegação inferior preserva regras de autenticação;
- tela permanece íntegra em `360 × 640 px`;
- carregamento, vazio e erro são tratados;
- acessibilidade e redução de movimento são respeitadas.
