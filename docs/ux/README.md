# UX Boards

Cada jornada do Clube da Regua possui um UX Board oficial. Os arquivos
`board.png` são a fonte de verdade da jornada, arquitetura da informação e
intenção de uso, e não devem ser alterados durante implementações.

Os boards atuais preservam composições e ativos de versões anteriores da marca.
Para cores, tipografia, logos, iconografia, movimento e componentes, a Marca V3
e a UI Specification V3 aprovada sempre prevalecem, conforme
`docs/brand/ADR-001-V3-AUTORIDADE-VISUAL.md`.

Toda implementação deve respeitar primeiro a jornada do board aprovado e,
depois, a UI Specification e a issue técnica. Quando houver conflito funcional
entre a issue e o board, o board orienta a decisão de UX; quando o conflito for
visual, a Marca V3 orienta a decisão.

| Jornada | Status |
| --- | --- |
| UX-001 — Primeiro Acesso | ✅ |
| UX-002 — Descobrir Barbearias | ✅ |
| UX-003 — Perfil da Barbearia | Em construcao |
| UX-004 — Escolha do Servico | Em construcao |
| UX-005 — Escolha do Barbeiro | Em construcao |
| UX-006 — Escolha do Horario | Em construcao |
| UX-007 — Login Inteligente | Em construcao |
| UX-008 — Confirmacao de Agendamento | Em construcao |
| UX-009 — Historico | Em construcao |
| UX-010 — Perfil do Cliente | Em construcao |

## Fluxo Oficial

Ideia

↓

UX Board

↓

Aprovacao

↓

Issue Tecnica

↓

Implementacao

↓

Validacao

## Regras

- Nenhum board deve ser editado diretamente.
- Cada nova funcionalidade deve possuir UX Board aprovado antes de entrar em desenvolvimento.
- O Brand Kit e os documentos de marca em `docs/brand/` continuam obrigatorios.
- A implementacao deve respeitar a experiencia mobile first, dark first e premium definida nos boards.
