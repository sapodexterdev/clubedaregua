# Contrato verificável — Componentes compartilhados V3

## Status e escopo

Contrato normativo para implementação e revisão de Cliente e Gestão.

Este documento transforma as fundações existentes da Marca V3 em critérios
verificáveis para componentes compartilhados. Ele não cria uma nova linguagem
visual e não substitui a UI Specification de cada tela.

Estão cobertos:

- cards e superfícies;
- badges de status;
- estados vazio, erro e offline;
- snackbars;
- avatar e fallback de imagem;
- skeleton e loading;
- diálogos e bottom sheets;
- botões, campos, seletores e demais controles.

## Precedência

Aplicar a ordem definida em
`docs/brand/ADR-001-V3-AUTORIDADE-VISUAL.md`.

Este contrato define o comportamento-base dos componentes. A UI Specification
de uma tela pode escolher uma variante aqui prevista, mas não pode alterar
cores, famílias tipográficas, semântica, acessibilidade ou movimento sem
atualizar primeiro as fundações e este contrato.

## Fundações obrigatórias

### Cores

| Papel | Token V3 | Valor |
| --- | --- | --- |
| Fundo do app | Noite | `#09090B` |
| Superfície | Grafite | `#18181B` |
| Superfície elevada | Grafite elevado | `#27272A` |
| Borda | Borda | `#3F3F46` |
| Ação e seleção | Amarelo Régua | `#F3B200` |
| Ação hover | Amarelo hover | `#FFC62B` |
| Ação pressionada | Amarelo pressionado | `#D99F00` |
| Texto principal | Branco | `#FFFFFF` |
| Texto secundário | Texto secundário | `#A1A1AA` |
| Texto desabilitado | Desabilitado | `#71717A` |
| Sucesso | Sucesso | `#22C55E` |
| Aviso | Aviso | `#F97316` |
| Erro | Erro | `#EF4444` |
| Informação | Informação | `#38BDF8` |

O amarelo não substitui sucesso, aviso, erro ou informação. Cor nunca pode ser
o único meio de comunicar um estado.

### Tipografia

- Barlow Condensed: títulos de tela, títulos de seção e números de destaque.
- Inter: controles, navegação, labels, mensagens, listas e corpo.
- Corpo padrão: Inter `16/24`, peso `400`.
- Corpo pequeno: Inter `14/20`, peso `400`.
- Label: Inter `14/18`, peso `600`.
- Legenda: Inter `12/16`, peso `500`.

O lettering da marca nunca é reconstruído com fonte de interface.

### Espaçamento, raios e interação

- Usar exclusivamente a grade `4, 8, 12, 16, 20, 24, 32, 40, 48, 64`.
- Padding interno padrão de card e campo: `16 px`.
- Raios permitidos: pequeno `8 px`, médio `14 px`, grande `22 px`, app
  `28 px` e pílula `999 px`.
- Alvo interativo mínimo: `44 × 44 px`, inclusive quando o desenho visível for
  menor.
- Ícones funcionais: uma única família Material outline, normalmente entre
  `20–24 px`, com peso visual aproximado de `2 px`.
- Ícones não podem ser usados apenas como decoração nem substituir labels
  indispensáveis.

### Movimento

- Feedback imediato: `150 ms`.
- Troca de estado: `250 ms`.
- Ênfase de entrada: `400 ms`.
- Sem bounce, pulso automático, elasticidade ou glow contínuo.
- Com redução de movimento ativa, remover escala, parallax e deslocamentos;
  usar apenas fade entre `150–250 ms` quando necessário.
- Nenhuma navegação, gravação ou leitura pode depender do término de uma
  animação decorativa.

## Estado comum de componentes interativos

Todo componente interativo aplicável deve prever:

| Estado | Contrato |
| --- | --- |
| Padrão | Label, valor e ação claramente identificáveis. |
| Hover | Apenas Web/ponteiro; mudança discreta, sem deslocar layout. |
| Pressionado | Feedback em até `150 ms`; não alterar dimensões do layout. |
| Foco | Contorno visível com contraste AA; ordem de foco lógica. |
| Selecionado | Ícone, texto ou indicador acompanham a cor; nunca só a cor. |
| Desabilitado | Sem ação; aparência e semântica informam indisponibilidade. |
| Loading | Bloqueia repetição da ação e preserva largura/altura. |
| Erro | Mensagem humana associada ao componente e forma de correção. |
| Sucesso | Confirma o resultado sem manter destaque permanente desnecessário. |

## Card e superfície

### Variantes permitidas

#### Card padrão

- Fundo Grafite.
- Borda Borda de `1 px`.
- Raio médio ou grande, conforme densidade documentada pela tela.
- Padding padrão de `16 px`.
- Sem elevação visual por sombra; a hierarquia vem da superfície e da borda.

#### Card elevado

- Reservado a menus, modais e estados que realmente estejam acima do conteúdo.
- Fundo Grafite elevado.
- Não usar como substituto decorativo do card padrão.

#### Card selecionável

- Toda a área pode ser acionável quando houver um único destino.
- Seleção usa borda/ícone em Amarelo Régua e um rótulo ou indicador perceptível.
- Deve expor semanticamente `selecionado`.
- Não aninhar dois CTAs concorrentes sem que a spec da tela justifique a
  hierarquia.

#### Card de métrica

- Segue `UI-016`: ícone amarelo em cápsula discreta, número em Barlow
  Condensed e label secundária em cinza.
- A métrica deve ter nome, período ou contexto suficiente para não parecer um
  número isolado.

#### Card com mídia

- Imagem real usa `cover`, sem distorção.
- Proporção definida pela spec; capas de barbearia usam `16:9`.
- Placeholder, erro de imagem e fallback ocupam exatamente a mesma geometria.
- Badges sobre a imagem precisam manter contraste em qualquer fotografia.

### Estados verificáveis

- Padrão, pressionado e foco quando acionável.
- Selecionado quando fizer parte de uma escolha.
- Desabilitado quando a ação existir, mas estiver indisponível.
- Skeleton com a mesma geometria durante leitura.
- Conteúdo longo não pode sobrepor ações; truncamento precisa preservar a
  informação necessária à decisão.

## Badge de status

### Anatomia

- Contêiner em pílula.
- Label textual curta em Inter, nunca apenas um ponto colorido.
- Ícone outline opcional quando reforçar o significado.
- Área visual compacta; se acionável, o alvo total continua com pelo menos
  `44 × 44 px`.

### Semântica cromática

| Natureza | Cor | Exemplos de conteúdo |
| --- | --- | --- |
| Sucesso | `#22C55E` | `Confirmado`, `Concluído`, `Aberto` |
| Aviso | `#F97316` | `Estoque baixo`, `Atenção` |
| Erro | `#EF4444` | `Falhou`, `Cancelado` quando for falha crítica |
| Informação | `#38BDF8` | `Em processamento`, informação neutra relevante |
| Neutro | Texto secundário/Borda | `Inativo`, `Sem dados`, estado encerrado neutro |

O Amarelo Régua só é usado quando o estado representa seleção, ação ou destaque
de marca; não significa sucesso genérico.

### Conteúdo

- Preferir uma ou duas palavras.
- Usar a mesma label para o mesmo estado em Cliente e Gestão.
- Estado técnico do banco deve ser traduzido para linguagem de produto.
- Tooltip ou descrição acessível deve explicar termos abreviados.

## Estado vazio, erro e offline

Os três estados compartilham estrutura, mas nunca a mesma mensagem ou
semântica.

### Anatomia comum

1. ícone outline neutro ou semântico;
2. título direto;
3. apoio que explica o contexto;
4. ação apenas quando houver um próximo passo real.

Usar superfície Grafite, texto principal e secundário. O conteúdo deve caber
sem rolagem horizontal e respeitar a SafeArea.

### Vazio

- Explica que não existem dados para o contexto atual.
- Não usa cor de erro.
- Quando filtros causarem o vazio, oferecer `Limpar filtros`.
- Quando a criação for permitida, o CTA descreve a criação específica.

Exemplo aprovado: `Nenhuma barbearia encontrada.` +
`Tente alterar a busca, os filtros ou a localização.`

### Erro

- Informa o que não pôde ser carregado ou salvo.
- Nunca exibe endpoint, stack trace, status HTTP ou texto técnico.
- Quando a operação puder ser repetida com segurança, oferece
  `Tentar novamente`.
- Dados válidos já exibidos não devem ser apagados por falha de atualização.

Exemplo aprovado: `Não foi possível carregar as barbearias.` +
`Verifique sua conexão e tente novamente.`

### Offline

- Informa ausência de conexão e o impacto real sobre a ação atual.
- Conteúdo local ainda válido permanece visível sempre que possível.
- Retry não pode criar gravação duplicada.
- Não prometer sincronização em segundo plano se ela não existir.

### Acessibilidade

- Mudança para erro relevante deve ser anunciada por leitor de tela.
- O foco vai para o título do estado somente quando a mudança substitui o
  conteúdo principal; erros pontuais permanecem próximos da ação de origem.

## Snackbar

### Uso

- Feedback breve de sucesso, aviso, erro recuperável ou informação.
- Não usar para confirmação destrutiva, formulário complexo ou erro que exija
  leitura prolongada.
- Uma mensagem por resultado; não empilhar mensagens equivalentes.

### Visual e conteúdo

- Superfície Grafite elevado, borda discreta e texto Inter.
- Ícone e cor semântica opcionais reforçam o tipo, sem substituir o texto.
- Mensagem declara o resultado: `Configurações salvas com sucesso.`
- Ação opcional é curta e específica, como `Tentar novamente` ou `Desfazer`.
- Não usar `Algo deu errado`, `Erro inesperado` ou mensagem técnica.

### Comportamento e acessibilidade

- Deve permanecer tempo suficiente para leitura e pausar quando houver foco ou
  interação, conforme suporte da plataforma.
- Não cobre CTA fixo, navegação inferior nem teclado.
- Mensagem é anunciada como atualização de estado sem roubar foco.
- Uma ação crítica não pode existir somente na snackbar.

## Avatar e fallback de imagem

### Ordem de resolução

1. foto real válida do usuário, profissional ou barbearia;
2. inicial do nome quando a identificação pessoal estiver disponível;
3. avatar neutro com ícone outline para pessoa sem foto;
4. ativo V3 definido pela spec apenas quando o contexto for institucional.

Não apresentar fotografia genérica como se pertencesse à pessoa ou à
barbearia.

### Visual

- Recorte circular para pessoas; logos e ícones institucionais preservam a
  proporção oficial documentada.
- Borda Borda; Amarelo apenas para seleção, estado premium documentado ou ação
  de editar.
- Imagem usa `cover` e ponto focal central configurável.
- A geometria não muda entre carregando, sucesso, erro e fallback.
- Segunda logo `CR` tem mínimo digital de `48 px`; ícone do app não substitui
  automaticamente avatar pessoal.

### Conteúdo e acessibilidade

- Texto alternativo identifica a entidade, não descreve decoração.
- Avatar decorativo ao lado do mesmo nome pode ser excluído da árvore semântica.
- Ação de trocar foto precisa de label própria e alvo de `44 × 44 px`.

## Skeleton e loading

### Skeleton

- Preferencial para listas, cards e blocos cujo formato final é conhecido.
- Replica a geometria, quantidade visual aproximada e hierarquia do conteúdo.
- Usa Grafite/Grafite elevado; animação discreta, sem amarelo dominante.
- Não anima individualmente listas longas.
- Com redução de movimento, permanece estático.
- Ao concluir, substitui o bloco sem salto significativo de layout.

### Loading de seção

- Usado quando o formato final não é conhecido ou a área é pequena.
- Indicador discreto acompanhado de mensagem somente quando ela acrescentar
  contexto.
- Não bloqueia navegação ou conteúdo não relacionado.

### Loading de ação

- Mantém as dimensões do controle.
- Substitui ou acompanha o label sem permitir toques repetidos.
- Expõe semanticamente estado ocupado.
- Conclui em sucesso ou erro explícito; não permanece infinito sem saída.

### Loading de tela e Splash

- Loading interno não pode reabrir Splash, repetir autenticação nem reconstruir
  o aplicativo.
- Marca em tela cheia fica reservada à entrada institucional definida em
  `docs/brand/v3/MOTION_SYSTEM.md`.
- A cena da Splash ocorre uma única vez, dura no máximo `2000 ms` e não repete
  enquanto dados carregam.
- Se a carga continuar, a marca permanece estática e um indicador separado é
  exibido.

## Diálogo

### Uso

- Confirmação curta, decisão bloqueante ou informação que precisa ser resolvida
  antes de continuar.
- Não usar para formulários longos, navegação ou conteúdo exploratório.

### Anatomia

1. título em Inter ou Barlow Condensed conforme hierarquia da tela;
2. corpo Inter, curto e objetivo;
3. ação principal;
4. ação secundária quando existir alternativa segura.

- Fundo Grafite ou Grafite elevado, raio grande e sem sombra decorativa
  excessiva.
- Ação destrutiva usa semântica de erro e nunca se confunde com o CTA amarelo.
- Foco inicial fica na opção segura quando a ação for destrutiva.
- `Esc`, voltar do sistema e toque externo só fecham quando isso não descartar
  trabalho ou confirmar uma ação implicitamente.

### Acessibilidade

- Foco fica contido no diálogo e retorna ao controle que o abriu.
- Título é associado semanticamente ao conteúdo.
- Leitor de tela anuncia a natureza da confirmação e as ações.

## Bottom sheet

### Uso

- Escolhas, filtros, edição curta e ações contextuais em mobile.
- Formulário longo ou fluxo com várias etapas deve usar uma tela dedicada.

### Anatomia e comportamento

- Fundo Grafite, raio grande na borda superior e handle discreto quando puder ser
  arrastado.
- Respeita SafeArea e teclado; conteúdo pode rolar sem ocultar o CTA.
- CTA principal permanece acessível, sem cobrir o último campo.
- Fechar por swipe, voltar ou toque externo segue a mesma regra de descarte do
  diálogo.
- Em tablet/desktop, a spec pode usar diálogo ou painel adequado sem esticar o
  conteúdo móvel por toda a janela.

### Acessibilidade

- Foco entra no título ou primeiro controle útil e retorna à origem ao fechar.
- Handle visual não substitui botão ou gesto acessível de fechar.

## Botões

### Variantes

| Variante | Uso | Visual |
| --- | --- | --- |
| Primário | Única ação principal do contexto | Amarelo Régua, texto Noite |
| Secundário | Alternativa não destrutiva | Grafite, borda, texto branco |
| Outline | Ação de menor hierarquia | Transparente, borda, texto branco |
| Ghost | Ação discreta | Transparente, sem borda permanente |
| Destrutivo | Remoção/cancelamento irreversível | Semântica de erro, nunca amarelo |

- Altura visual pode ser `52 px` no componente padrão ou `56 px` no CTA
  proeminente já especificado; nunca abaixo do alvo mínimo de `44 px`.
- Raio vem apenas da escala V3. A spec da tela escolhe médio ou grande e deve
  manter a escolha para ações equivalentes.
- Label Inter, direta, acionável e em uma linha; ícone é opcional e não repete
  informação sem necessidade.
- Uma área não deve apresentar dois botões primários concorrentes.

### Estados

- Hover usa amarelo hover; pressionado usa amarelo pressionado.
- Loading mantém tamanho, bloqueia duplicação e informa estado ocupado.
- Desabilitado só quando o motivo estiver visível ou inferível no contexto.
- Foco visível com contraste AA.

## Campos de texto

### Anatomia

- Label persistente, valor, hint opcional, helper opcional e erro associado.
- Ícone leading/trailing apenas quando funcional ou informativo.
- Altura mínima de uma linha: `56 px`; múltiplas linhas crescem pela grade.
- Fundo Grafite, borda Borda, raio médio ou grande conforme a spec.
- Cursor e foco podem usar Amarelo Régua; erro usa Erro.

### Regras

- Placeholder não substitui label.
- Teclado, autofill e ação de entrada correspondem ao dado esperado.
- Erro explica como corrigir, preserva o valor e não altera a largura do campo.
- Campo desabilitado não pode parecer editável.
- Senha oferece mostrar/ocultar com label acessível.

## Seletores e controles

### Checkbox, radio e switch

- Usar checkbox para múltipla escolha, radio para escolha exclusiva e switch
  para alteração imediatamente aplicada.
- Label inteira é acionável e descreve o efeito.
- Selecionado usa Amarelo Régua mais marca visual própria do controle.
- Mudanças que dependem de `Salvar` não devem ser apresentadas como switch de
  efeito imediato sem explicação.

### Chips

- Altura interativa mínima de `44 px` quando acionáveis.
- Fundo Grafite, borda Borda, raio pílula, label Inter.
- Selecionado usa borda e ícone amarelos; o texto permanece legível.
- Listas horizontais não cortam primeiro ou último chip.
- Chip de status segue o contrato de badge e não se comporta como filtro.

### Controle segmentado

- Exclusivo para poucas opções mutuamente exclusivas e de mesma hierarquia.
- Selecionado em Amarelo Régua com texto Noite; demais opções em superfície
  escura com texto secundário.
- No seletor profissional, os labels oficiais são `Barbeiro` e `Dono`.
- A troca de modo não pode reabrir Splash ou autenticação.
- Em desktop, permanece compacto; não ocupa a largura total sem necessidade.

### Data e horário

- Seleção atual é textual e visualmente evidente.
- Opção visual de `40 px` deve estar dentro de alvo interativo de pelo menos
  `44 px`.
- Horários indisponíveis são desabilitados e não dependem só de opacidade.
- Loading limpa seleções antigas quando elas deixarem de ser válidas.

### Ícone de ação e voltar

- Alvo mínimo `44 × 44 px`, ícone entre `20–24 px` e tooltip/label semântico.
- Voltar usa o comportamento da pilha atual; não cria uma rota duplicada.
- Ícone destrutivo usa semântica de erro e exige confirmação proporcional ao
  impacto.

## Responsividade comum

### Cliente

- Frame móvel com largura máxima de `430 px` enquanto vigente o contrato
  mobile-first.
- Margem lateral padrão de `24 px` e SafeArea obrigatória.

### Gestão

- Mobile `< 600 px`: uma coluna, margem `16–20 px`, navegação inferior.
- Tablet `600–1023 px`: navegação lateral compacta, margem `24 px`, até duas
  colunas quando houver espaço.
- Desktop `>= 1024 px`: navegação lateral, barra superior e conteúdo até
  `1280 px` com margens `24–32 px`.

Componentes não podem ser esticados apenas para preencher a viewport. Conteúdo
e ações preservam hierarquia, legibilidade e tamanho de toque em todos os
breakpoints.

## Checklist de aceite por componente

Para considerar um componente compartilhado conforme:

- [ ] Usa somente tokens V3 e uma variante documentada neste contrato.
- [ ] Tipografia usa explicitamente Barlow Condensed ou Inter conforme o papel.
- [ ] Espaçamento e raio pertencem às escalas oficiais.
- [ ] Possui alvo mínimo, foco visível, ordem de foco e semântica acessível.
- [ ] Padrão, hover, pressionado, foco, selecionado, desabilitado, loading,
      erro e sucesso foram avaliados quando aplicáveis.
- [ ] Não comunica estado somente por cor ou ícone.
- [ ] Conteúdo segue Voice and Tone e informa o próximo passo.
- [ ] Movimento usa `150/250/400 ms` e respeita redução de movimento.
- [ ] SafeArea, teclado, `360 × 640 px`, tablet e desktop foram avaliados
      conforme o app consumidor.
- [ ] Loading, vazio, erro, offline e retry não duplicam requisições ou ações.
- [ ] Cliente e Gestão usam a mesma anatomia e semântica para o mesmo papel.
- [ ] A UI Specification da tela registra qualquer escolha entre variantes.

## Evidências mínimas de revisão

- captura ou teste visual nos breakpoints afetados;
- inspeção de contraste e foco no Web;
- navegação por teclado quando aplicável;
- leitura por Semantics/tecnologia assistiva nos controles críticos;
- redução de movimento habilitada;
- conteúdo longo, escala de texto ampliada, loading, vazio, erro e offline;
- comparação lado a lado do mesmo componente em Cliente e Gestão.
