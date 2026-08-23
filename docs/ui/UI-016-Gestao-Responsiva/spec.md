# Especificação — Gestão Responsiva

## Objetivo

Transformar a Gestão em uma ferramenta operacional dark first, premium e
coerente com o App Cliente, preservando velocidade de leitura e operação.

## Shell

### Desktop (`>= 1024 px`)

- navegação lateral com largura entre `88` e `240 px`;
- barra superior grafite com título da seção e ações globais;
- conteúdo central com largura máxima de `1280 px`;
- margens laterais de `24–32 px`;
- não utilizar navegação inferior;
- não esticar cards para preencher toda a janela.

### Tablet (`600–1023 px`)

- navegação lateral compacta;
- conteúdo fluido com `24 px` de margem;
- grades com duas colunas quando houver espaço.

### Mobile (`< 600 px`)

- navegação inferior;
- cabeçalho compacto;
- conteúdo em uma coluna;
- margem lateral de `16–20 px`.

## Cores

- fundo: Noite `#09090B`;
- superfície: Grafite `#18181B`;
- superfície elevada: `#27272A`;
- borda: `#3F3F46`;
- ação: Amarelo Régua `#F3B200`;
- texto principal: branco;
- texto auxiliar: `#A1A1AA`.

Cards brancos são proibidos no shell e nos módulos operacionais.

## Tipografia

- título de tela e números: Barlow Condensed `700–800`;
- navegação, campos e corpo: Inter `400–700`;
- título de tela desktop: `28–32 px`;
- título de seção: `22–24 px`;
- números de métrica: `30–36 px`.

## Componentes

### Métrica

- card Grafite com borda;
- ícone amarelo dentro de cápsula discreta;
- número em Barlow Condensed;
- label secundária em cinza.

### Lista operacional

- superfície Grafite;
- hierarquia: pessoa/serviço, horário/status e ações;
- ação principal amarela;
- ações secundárias escuras com borda;
- status em badges semânticos.

### Seletor Barbeiro/Dono

- controle segmentado compacto;
- selecionado em Amarelo Régua com texto Noite;
- não ocupar toda a largura no desktop.

## Estados

Loading, vazio, erro e sucesso usam a mesma superfície Grafite. Erros técnicos
nunca aparecem diretamente para o usuário.

## Acessibilidade

- contraste mínimo AA;
- alvos interativos com pelo menos `44 px`;
- foco visível no Web;
- informações não dependem exclusivamente da cor.
