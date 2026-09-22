# Painel do Dono — indicadores e evolução

## Objetivo

Dar ao dono uma leitura rápida e confiável da operação, com números reais da
barbearia selecionada e sem estimativas apresentadas como receita recebida.

## Hierarquia da tela

1. Manter o cabeçalho global da barbearia no shell; a página não repete o nome.
2. Exibir título “Seus números, com clareza” e filtros “Hoje”, “7 dias” e
   “30 dias” usando `ChoiceChip` e os estados do tema.
3. Mostrar cards de Agendamentos, Confirmados, Previsto e Recebido.
4. Mostrar Ticket médio de serviço e o gráfico diário de recebimentos e
   atendimentos.
5. Usar estados distintos para carregamento, erro com nova tentativa e período
   sem movimentação.

## Identidade e responsividade

- Reutilizar `CDRCard`, `_IconBadge`, `_SectionTitle`, espaçamentos, tipografia,
  cores e raios definidos no design system compartilhado.
- Preservar o fundo grafite, cartões escuros, contornos discretos e dourado como
  destaque; cinza é reservado à série de atendimentos e texto secundário.
- Cards reorganizam-se com `Wrap` em telas estreitas e duas colunas quando há
  espaço suficiente. Filtros também podem quebrar linha sem overflow.
- O gráfico inclui resumo acessível e rótulos de data; sua legenda informa que
  as séries têm escalas visuais próprias.

## Regras dos indicadores

- Períodos são calculados pela data local e timezone da barbearia.
- Agendamentos contam registros não cancelados pela data/hora marcada.
- Confirmados contam status `confirmed`.
- Previsto soma valores de agendamentos `pending` e `confirmed`.
- Recebido soma pagamentos `paid` pela data de recebimento e vendas de produtos
  concluídas pela data da venda.
- Ticket médio de serviço = pagamentos recebidos de agendamentos dividido pelo
  número de atendimentos concluídos no período; vendas de produtos ficam fora.
- O gráfico contém um ponto para cada dia, inclusive sem movimento.

## Backend e segurança

O Flutter chama `get_owner_dashboard_metrics` com o ID da barbearia e um período
permitido (1, 7 ou 30 dias). A RPC valida `is_shop_owner_or_manager`, usa o fuso
da unidade, limita as consultas àquela barbearia e devolve totais e série diária.
Aplicar `supabase/issue_028_owner_dashboard_period_trend.sql` após a ISSUE-027.
