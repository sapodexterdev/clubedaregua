# Comissão do Barbeiro — V3

## Objetivo

Dar ao profissional uma visão simples e verificável da própria produção e da
comissão calculada, sem confundir valores calculados com pagamentos realizados.

## Hierarquia e comportamento

1. Usar o cabeçalho global da Gestão, sem repetir o cartão da barbearia.
2. Título: `Sua comissão, com clareza`.
3. Filtros de período `Hoje`, `7 dias` e `30 dias`, com datas baseadas no fuso
   horário cadastrado pela barbearia.
4. Indicadores: `Produção do período`, `Percentual aplicado` e
   `Comissão calculada`.
5. Produção considera somente agendamentos `completed`, pela data/hora em que
   foram concluídos (`appointments.completed_at`), usando o valor efetivamente
   registrado no agendamento.
6. Comissão é produção concluída multiplicada pelo percentual atual cadastrado
   para o profissional. O percentual ainda não é um snapshot por atendimento;
   portanto a tela e a spec devem explicitar que alterações futuras na taxa
   podem mudar recálculos históricos. Em registros legados, `completed_at` é
   preenchido com `updated_at` como aproximação, pois não havia instante de
   conclusão separado; a interface informa essa limitação.
7. A tela não afirma que a comissão foi paga nem exibe saldo de repasse: o
   sistema ainda não registra liquidações de comissão.
8. Estado sem atendimentos concluídos informa o próximo passo; erro oferece
   nova tentativa e carregamento tem estado próprio.

## Identidade e responsividade

- Seguir `docs/brand/ADR-001-V3-AUTORIDADE-VISUAL.md`, os tokens V3 e
  `docs/ui/SHARED_COMPONENTS_V3.md`.
- Fundo Noite, cards Grafite com borda, destaque Amarelo Régua e tipografia
  Barlow Condensed para números; Inter para controles e mensagens.
- Filtros quebram linha quando necessário. Cards usam uma coluna no mobile,
  duas em viewport média e três no desktop, respeitando escala de texto.
- Loading, vazio e erro são semanticamente distintos.

## Backend e segurança

O Flutter chama `get_barber_commission_metrics` com períodos permitidos (1, 7
ou 30 dias). A RPC usa o fuso da unidade e identifica o profissional por
`auth.uid()` vinculado a um cadastro ativo naquela barbearia; o UUID de unidade
enviado pelo cliente não concede acesso. Somente os próprios atendimentos
concluídos entram no agregado.

Em instalações existentes, aplicar
`supabase/issue_030_barber_commission_metrics.sql` no Supabase antes de usar a
tela. A migration também adiciona `completed_at` e atualiza a RPC existente de
conclusão, preservando sua autorização e registrando o instante real para novos
atendimentos.
