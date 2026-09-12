# UI Specifications

UI Specifications representam a implementacao visual final de cada tela do Clube da Regua.

Enquanto os UX Boards documentam a experiencia, jornadas e intencoes de uso, as UI Specifications documentam exatamente como cada tela deve ser construida visualmente.

Toda implementação Flutter deve seguir a Marca V3 e a UI Specification V3
aprovada para a tela correspondente. Specs anteriores à V3 permanecem como
referência funcional até serem migradas.

Os componentes equivalentes de Cliente e Gestão seguem obrigatoriamente o
contrato `SHARED_COMPONENTS_V3.md`. A spec de tela seleciona as variantes
permitidas e define a composição, sem criar um componente paralelo.

Shell, destinos raiz, Perfil, troca de modo e comportamento de Voltar seguem o
contrato `SHARED_NAVIGATION_V3.md`.

## Niveis de Documentacao

Brand -> identidade visual

Experience -> experiencias completas

UX -> jornadas do usuario

UI -> especificacao visual de cada tela

## Fluxo Oficial

Brand

->

Experience

->

UX

->

Contrato de componentes compartilhados

->

Contrato de shell e navegação

->

UI Specification

->

Issue Tecnica

->

Implementacao

## Telas Mapeadas

- `UI-001-Splash`
- `UI-002-Onboarding-01`
- `UI-003-Onboarding-02`
- `UI-004-Onboarding-03` — etapa 3 Explorar, aprovada V3
- `UI-005-Onboarding-04` — histórico arquivado; não há quarta etapa
- `UI-006-Home-Publica`
- `UI-007-Perfil-Barbearia`
- `UI-008-Ver-Horarios`
- `UI-009-Revisar-Agendamento`
- `UI-010-Solicitacao-Enviada`
- `UI-011-Agenda`
- `UI-012-Favoritos`
- `UI-013-Perfil-Cliente`
- `UI-014-Notificacoes`
- `UI-015-Conversao-Agendamento`
- `UI-016-Gestao-Responsiva`

## Regra de Implementacao

Antes de implementar ou alterar qualquer tela, deve existir uma UI Specification aprovada.

Se a implementação Flutter divergir da especificação visual oficial, prevalece
a UI Specification V3 aprovada. Se uma spec histórica divergir das fundações
V3, prevalece `docs/brand/ADR-001-V3-AUTORIDADE-VISUAL.md` e a spec deve ser
atualizada antes da implementação.
