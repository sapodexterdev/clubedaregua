# Painel do Dono — indicadores e evolução

## Objetivo

Dar ao dono uma leitura rápida e confiável da operação, com números reais da
barbearia selecionada e sem estimativas apresentadas como receita recebida.

## Hierarquia da tela

1. Manter o cabeçalho global da barbearia no shell; a página não repete o nome.
2. Exibir título “Seus números, com clareza” e filtros “Hoje”, “7 dias” e
   “30 dias” usando `ChoiceChip` e os estados do tema.
3. Mostrar cards operacionais de Agendamentos, Cancelados, Atendidos e Clientes
   novos; manter Previsto e Recebido como indicadores financeiros.
4. Mostrar Ticket médio de serviço e o gráfico diário de recebimentos e
   agendamentos não cancelados.
5. Cards operacionais com contagem maior que zero abrem uma tela de detalhe
   empilhada sobre o Painel. Essa tela mantém o período aplicado e não exibe a
   navegação raiz enquanto está aberta. Cards zerados são apenas informativos.
6. Usar estados distintos para carregamento, erro com nova tentativa e período
   sem registros.

## Identidade e responsividade

- Reutilizar `CDRCard`, `_IconBadge`, `_SectionTitle`, espaçamentos, tipografia,
  cores e raios definidos no design system compartilhado.
- Preservar o fundo grafite, cartões escuros, contornos discretos e dourado como
  destaque; cinza é reservado à série de agendamentos e ao texto secundário.
- Cards reorganizam-se com `Wrap` em telas estreitas e duas colunas quando há
  espaço suficiente. Filtros também podem quebrar linha sem overflow.
- Cards navegáveis usam o estado de toque do `CDRCard`, indicador de avanço e
  semântica de botão; card sem registros informa que não abre detalhes.
- A lista de detalhe reutiliza `CDRCard`, cores semânticas, tipografia e os
  estados de vazio, erro e carregamento do design system.
- O gráfico inclui resumo acessível e rótulos de data; sua legenda informa que
  as séries têm escalas visuais próprias.

## Regras dos indicadores

- Períodos são calculados pela data local e timezone da barbearia.
- Agendamentos contam registros não cancelados pela data/hora marcada.
- Cancelados contam registros com status `cancelled` pela data/hora marcada;
  como o schema não guarda o instante do cancelamento, esse indicador não
  representa necessariamente o dia em que a ação de cancelar ocorreu.
- Atendidos contam status `completed` pela data/hora marcada.
- Clientes novos contam a primeira relação com a unidade (`first_seen_at`), não
  a criação global da conta do cliente.
- Previsto soma valores de agendamentos `pending` e `confirmed`.
- Recebido soma pagamentos `paid` pela data de recebimento e vendas de produtos
  concluídas pela data da venda.
- Ticket médio de serviço = pagamentos recebidos de agendamentos dividido pelo
  número de atendimentos concluídos no período; vendas de produtos ficam fora.
- O gráfico contém um ponto para cada dia, inclusive sem movimento.

## Backend e segurança

O Flutter chama `get_owner_dashboard_metrics_v2` com o ID da barbearia e um período
permitido (1, 7 ou 30 dias). A RPC valida `is_shop_owner_or_manager`, usa o fuso
da unidade, limita as consultas àquela barbearia e devolve totais e série diária.
A tela de detalhe chama `get_owner_dashboard_details` com o tipo do card e o
mesmo período; a RPC também valida o acesso e mantém o escopo da unidade.

Para atualizar instalações que já aplicaram as migrations anteriores, aplicar
`supabase/issue_029_owner_dashboard_details.sql` após a ISSUE-028. Ela atualiza
a funcionalidade por meio de uma nova RPC de métricas e cria a RPC de detalhes,
mantendo a versão anterior disponível para clientes que ainda estejam abertos.
