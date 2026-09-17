# Contrato verificável — Shell e navegação V3

## Status e objetivo

Contrato normativo para Cliente, Barbeiro e Dono.

Este documento define a arquitetura de informação e o comportamento do shell
único do Clube da Régua em mobile, tablet e desktop. Ele preserva:

- descoberta pública como entrada principal do Cliente;
- uma única aplicação e uma única sessão;
- modos profissionais chamados **Barbeiro** e **Dono**;
- troca de modo somente pelo Perfil;
- último modo utilizado sem navegação ou inicialização duplicada.

O contrato visual geral dos controles permanece em
`SHARED_COMPONENTS_V3.md`.

## Princípios de navegação

1. Destinos raiz representam áreas irmãs. Alternar entre eles não empilha uma
   nova cópia da tela nem simula uma navegação de detalhe.
2. Telas de detalhe, criação, edição e confirmação pertencem ao destino raiz
   que as abriu e entram acima dele.
3. Cliente, Barbeiro e Dono usam a mesma sessão autenticada. Trocar de modo não
   executa Splash, login, bootstrap ou listener de autenticação novamente.
4. Destinos não autorizados não aparecem. Ocultar navegação não substitui a
   autorização no Supabase.
5. O shell não depende de parâmetros `?mode=...`, redirecionamento para outro
   build ou alteração direta de `window.location`.
6. O estado ativo é derivado da rota atual. Persistência nunca dispara nova
   navegação quando modo e rota já estiverem corretos.
7. O conteúdo mantém título e contexto próprios; o usuário nunca precisa
   inferir em qual modo ou área está.

## Destinos raiz

### Cliente

| Ordem | Destino | Acesso | Papel |
| --- | --- | --- | --- |
| 1 | Descobrir | Público | Home discovery first, busca e barbearias. |
| 2 | Favoritos | Autenticado | Barbearias salvas pelo Cliente. |
| 3 | Agenda | Autenticado | Agendamentos do Cliente. |
| 4 | Perfil | Autenticado | Conta, preferências e troca de modo. |

`Descobrir` é a raiz inicial e o fallback do modo Cliente. A abertura pública
de uma pessoa sem modo anterior válido não pode ser desviada para login,
seleção profissional ou Gestão.

Quando um visitante toca Favoritos, Agenda ou Perfil:

- solicitar autenticação somente nesse momento;
- preservar o destino solicitado;
- após sucesso, abrir diretamente o destino preservado;
- cancelar o login retorna ao contexto público anterior.

### Barbeiro

| Ordem | Destino | Papel |
| --- | --- | --- |
| 1 | Agenda | Atendimentos confirmados e operação do dia. |
| 2 | Horários | Disponibilidade do próprio profissional. |
| 3 | Clientes | Clientes já atendidos pelo profissional. |
| 4 | Comissão | Comissão e faturamento do próprio profissional. |
| 5 | Pedidos | Histórico ou triagem operacional ainda disponível. |

`Agenda` é a raiz inicial e o fallback do modo Barbeiro. A confirmação
automática torna a agenda a principal superfície operacional; `Pedidos` não
pode exigir aceite manual para criar cada agendamento.

### Dono

| Ordem | Destino | Papel |
| --- | --- | --- |
| 1 | Painel | Visão geral da barbearia. |
| 2 | Agenda | Agenda consolidada por profissional. |
| 3 | Clientes | Controle de clientes e bloqueios autorizados. |
| 4 | Caixa | Caixa, produtos, estoque e vendas. |
| 5 | Pedidos | Histórico ou triagem operacional ainda disponível. |
| 6 | Serviços | Catálogo de serviços. |
| 7 | Equipe | Profissionais e acessos da unidade. |
| 8 | Configurações | Identidade e regras operacionais da barbearia. |

`Painel` é a raiz inicial e o fallback do modo Dono. Usar sempre
`Configurações`, nunca a abreviação `Config`, em labels visíveis e acessíveis.

## Perfil e troca de modo

### Ponto único de troca

- No Cliente, Perfil é o quarto destino raiz.
- No Barbeiro e no Dono, Perfil é uma ação global no cabeçalho, representada por
  avatar ou ícone de pessoa com label acessível `Abrir Perfil`.
- O seletor Barbeiro/Dono não aparece no conteúdo das páginas, no cabeçalho nem
  como destino raiz.

### Conteúdo do Perfil

A seção `Modo de uso` apresenta somente modos permitidos ao usuário:

- `Cliente`;
- `Barbeiro`, quando houver acesso profissional válido;
- `Dono`, quando houver acesso de proprietário válido.

Cada opção apresenta label, descrição curta e estado atual. O nome técnico
`admin` não aparece na interface.

### Comportamento da troca

1. Validar o acesso ao modo escolhido sem encerrar a sessão.
2. Se o modo escolhido já estiver ativo e a rota for válida, fechar o Perfil e
   manter a tela atual, sem navegação adicional.
3. Ao trocar, persistir o último modo somente depois da validação.
4. Abrir a última raiz válida daquele modo; se não existir, usar a raiz inicial:
   Descobrir, Agenda ou Painel.
5. Substituir o shell atual, sem deixar uma cópia anterior abaixo dele.
6. Preservar token, identidade e dados compartilhados; carregar somente dados
   ainda ausentes do destino selecionado.
7. Falha mantém o modo atual e apresenta mensagem com próximo passo.

Troca de modo não pode mostrar `Preparando sua área profissional...`, repetir
Splash, recarregar a página ou alterar a URL quando ela já representar o modo
correto.

## Shell por largura

Os breakpoints profissionais seguem a Marca V3:

- mobile: `< 600 px`;
- tablet: `600–1023 px`;
- desktop: `>= 1024 px`.

### Cliente mobile

- Navegação inferior com os quatro destinos na ordem oficial.
- Altura visual `72 px` mais SafeArea inferior.
- Ícone outline `22–24 px` e label sempre visível.
- Nenhum destino vai para `Mais`.
- Telas de detalhe ocultam a navegação inferior quando a ação principal fixa ou
  o fluxo exigir foco; Voltar retorna à raiz de origem.

### Cliente tablet e desktop

- Enquanto o Cliente permanecer mobile-first, a experiência fica centralizada
  em frame de até `430 px`.
- A navegação inferior permanece dentro desse frame; não criar rail ou sidebar
  apenas para preencher o navegador.
- O fundo externo não recebe destinos ou ações paralelas.
- SafeArea simulada não pode remover padding real quando executado em tablet ou
  PWA instalado.

### Barbeiro mobile

- Navegação inferior com os cinco destinos na ordem oficial.
- Labels permanecem visíveis; não usar rolagem horizontal.
- Perfil, atualizar, notificações e sair ficam em ações globais do cabeçalho ou
  em menu contextual, nunca como sexto destino.

### Dono mobile

A navegação inferior apresenta no máximo cinco itens:

1. Painel;
2. Agenda;
3. Clientes;
4. Caixa;
5. Mais.

`Mais` abre um bottom sheet com:

1. Pedidos;
2. Serviços;
3. Equipe;
4. Configurações.

Regras do overflow:

- cada item tem ícone outline, label completa e descrição curta opcional;
- o sheet respeita o contrato V3 de bottom sheet, SafeArea e teclado;
- selecionar um item fecha o sheet e abre aquela raiz uma única vez;
- `Mais` fica ativo quando Pedidos, Serviços, Equipe ou Configurações estiverem
  abertos;
- o título do cabeçalho exibe o destino real, nunca apenas `Mais`;
- Perfil, atualizar, notificações e sair não se misturam aos destinos de
  negócio; ficam em uma seção de conta/ações globais claramente separada.

### Barbeiro e Dono no tablet

- Usar rail lateral compacto com todos os destinos do modo.
- Ícone ativo e indicador permanecem visíveis; cada item oferece tooltip com a
  label completa.
- Configurações pode ficar no final do rail, separada dos destinos
  operacionais, mas mantém a mesma semântica de raiz.
- Não usar navegação inferior em paralelo ao rail.
- Perfil fica no cabeçalho ou no rodapé do rail e não altera a contagem de
  destinos.
- Em pouca altura, landscape ou texto ampliado, o conjunto de destinos do rail
  deve rolar dentro da área de navegação; nenhum item pode ser cortado ou ficar
  inacessível.

### Barbeiro e Dono no desktop

- Usar sidebar entre `88–240 px`, compacta ou estendida conforme espaço.
- Exibir todos os destinos autorizados; não usar `Mais` para destinos de negócio
  quando houver espaço vertical suficiente.
- Sidebar estendida mostra ícone e label; compacta mostra tooltip obrigatório.
- Barra superior exibe título da raiz, contexto da barbearia e ações globais.
- Conteúdo central permanece limitado a `1280 px` e não se estende sob a
  sidebar.
- Não usar navegação inferior.

## Estado ativo

### Aparência

- Ícone/indicador ativo em Amarelo Régua.
- Label ativa com contraste de texto principal.
- Item inativo em Texto secundário.
- O ativo usa também forma, preenchimento de ícone ou indicador; nunca depende
  somente da cor.
- Transição de seleção dura `250 ms`; sem bounce, pulso ou glow.

### Semântica

- Expor `selecionado` ao leitor de tela.
- Anunciar `Destino, selecionado`, sem repetir o nome do modo em cada item.
- Em `Mais`, anunciar qual destino interno está ativo.
- Foco por teclado é independente da seleção e permanece visível.

### Consistência de rota

- Apenas um destino raiz pode estar ativo.
- Abrir detalhe mantém a raiz de origem ativa.
- Deep link válido ativa a raiz correspondente.
- Rota ausente ou não autorizada usa a raiz inicial do modo, sem ciclo de
  redirecionamento.

## Comportamento de Voltar

Aplicar nesta ordem:

1. fechar menu, diálogo, bottom sheet ou teclado que esteja consumindo Voltar;
2. fechar uma tela de detalhe/edição e retornar à raiz que a abriu;
3. cancelar autenticação e retornar ao destino público preservado;
4. em uma raiz secundária, ir para a raiz inicial do modo sem empilhar rota;
5. na raiz inicial, delegar ao comportamento da plataforma: histórico válido no
   navegador ou saída/minimização quando suportada.

Regras adicionais:

- Voltar nunca abre Splash, onboarding ou login já concluído.
- Trocar destino raiz não cria histórico infinito de abas.
- Voltar de Dono para Barbeiro, ou de profissional para Cliente, só ocorre se o
  usuário tiver feito essa troca pelo Perfil; o botão não alterna modos
  implicitamente.
- Após logout, Voltar não reabre conteúdo privado em cache.
- No navegador, sincronizar rota e histórico sem `window.location.reload`.

## SafeArea e barras do sistema

- Cabeçalho respeita SafeArea superior, notch e Dynamic Island.
- Navegação inferior inclui SafeArea inferior e não é coberta pelo indicador
  Home do iPhone.
- Conteúdo rolável recebe padding suficiente para não terminar atrás da
  navegação, CTA fixo ou teclado.
- Bottom sheets e diálogos respeitam `viewInsets` e SafeArea.
- Em PWA instalado, mudanças de altura da viewport não remontam o shell nem
  alteram o destino ativo.
- Tablet/desktop respeitam áreas seguras, zoom e scrollbar sem cortar rail,
  sidebar ou cabeçalho.

## Labels e iconografia

Labels oficiais são:

- Cliente: `Descobrir`, `Favoritos`, `Agenda`, `Perfil`;
- Barbeiro: `Agenda`, `Horários`, `Clientes`, `Comissão`, `Pedidos`;
- Dono: `Painel`, `Agenda`, `Clientes`, `Caixa`, `Pedidos`, `Serviços`,
  `Equipe`, `Configurações`;
- overflow: `Mais`;
- modos: `Cliente`, `Barbeiro`, `Dono`.

Regras:

- Inter `500–700`, com tamanho compatível com o componente e escala de texto.
- Usar português acentuado; não truncar labels na navegação estendida.
- Não usar `Admin`, `Administrador`, `Config` ou labels técnicas na interface.
- Ícones seguem uma única família Material outline; versão preenchida pode
  reforçar o estado ativo.
- Não usar ícone sem tooltip em rail/sidebar compacta ou ação global.
- O mesmo destino usa o mesmo ícone e a mesma label em todos os breakpoints.

## Acessibilidade

- Alvo mínimo `44 × 44 px` para todo destino e ação.
- Ordem de foco: ação Voltar, título/contexto, ações globais, destinos e
  conteúdo, ajustada à leitura natural do layout.
- Rail/sidebar e bottom navigation expõem papel de navegação e seleção.
- Menu `Mais` recebe foco ao abrir, contém o foco enquanto modal e devolve o
  foco ao item `Mais` ao fechar.
- Mudança de raiz move o foco para o título principal do novo conteúdo no Web;
  toque mobile não produz anúncio duplicado.
- Escala de texto ampliada não oculta labels; quando faltar espaço, migrar para
  layout adequado ao breakpoint em vez de reduzir a fonte abaixo do contrato.
- Contraste mínimo AA e informação nunca somente por cor.
- Navegação completa funciona por teclado: Tab, Shift+Tab, Enter/Espaço e Esc
  quando aplicável.

## Persistência de estado

- Persistir o último modo validado: Cliente, Barbeiro ou Dono.
- Persistir a última raiz válida separadamente por modo quando isso não expuser
  conteúdo não autorizado.
- Não persistir modais, sheets, estados de loading ou detalhes transitórios.
- Após alteração de permissão, invalidar destino não autorizado e usar a raiz
  inicial do modo.
- Restaurar scroll e filtros de uma raiz é permitido, mas nunca à custa de
  memória ilimitada ou dados obsoletos apresentados como atuais.

## Checklist verificável

- [ ] Cliente sem raiz anterior válida abre em Descobrir sem login e mantém
      quatro destinos oficiais.
- [ ] Favoritos, Agenda e Perfil preservam o destino após autenticação.
- [ ] Barbeiro sem raiz anterior válida abre em Agenda e exibe cinco raízes
      autorizadas.
- [ ] Dono sem raiz anterior válida abre em Painel; mobile usa quatro raízes +
      Mais.
- [ ] `Mais` contém Pedidos, Serviços, Equipe e Configurações, e fica ativo para
      qualquer uma delas.
- [ ] Tablet usa rail e desktop usa sidebar; nenhuma largura mostra duas
      navegações raiz simultâneas.
- [ ] Perfil é o único ponto de troca Cliente/Barbeiro/Dono.
- [ ] Trocar para o modo já ativo não navega nem recarrega.
- [ ] Troca de modo preserva sessão e não exibe Splash/loading institucional.
- [ ] Último modo e última raiz são restaurados somente quando autorizados.
- [ ] Um único destino fica ativo, inclusive em deep links e detalhes.
- [ ] Voltar obedece à ordem modal → detalhe → raiz inicial → plataforma.
- [ ] SafeArea funciona em iPhone/PWA, tablet e desktop.
- [ ] Labels oficiais estão completas, acentuadas e sem `Admin` ou `Config`.
- [ ] Estado ativo tem cor + forma/ícone + semântica selecionada.
- [ ] Navegação possui alvos de `44 px`, foco, tooltips e teclado.
- [ ] Nenhuma rota usa redirecionamento para outro build, query `mode`, reload ou
      alteração direta de `window.location`.

## Evidências mínimas de revisão

- Cliente visitante e autenticado em `360 × 640`, `390 × 844` e frame `430 px`;
- Barbeiro e Dono em mobile `< 600 px`;
- rail em `768 px`, inclusive `768 × 600` em landscape, e sidebar em `1024 px`
  e `1440 px`;
- iPhone Safari e PWA instalado com SafeArea e teclado;
- troca repetida Cliente → Barbeiro → Dono → Barbeiro;
- deep link para uma raiz permitida e uma não autorizada;
- Voltar em modal, detalhe, raiz secundária e raiz inicial;
- teclado, leitor de tela, texto ampliado e redução de movimento;
- sessão Supabase e último modo preservados durante toda a sequência.
