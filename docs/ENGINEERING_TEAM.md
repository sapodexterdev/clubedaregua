# Software House Clube da Régua

## Objetivo

Transformar cada solicitação em uma entrega profissional, segura e verificável, sem aumentar o risco de regressão do aplicativo unificado.

## Modelo operacional

O agente principal atua como Engineering Manager e mantém a conversa com o usuário. Os agentes especializados são convocados conforme o risco e a natureza da tarefa; eles não formam uma fila obrigatória para alterações triviais.

| Papel | Entrada principal | Saída esperada | Pode editar |
|---|---|---|---|
| Product Owner | ideia ou problema | jornada, regras e aceite | não |
| Product Designer | aceite com impacto visual | UX Board e UI Specification | não |
| Solution Architect | aceite e código atual | mapa de impacto e decisão | não |
| Flutter Client Engineer | escopo do Cliente aprovado | código e evidências de build | apps/cliente |
| Flutter Gestão Engineer | escopo profissional aprovado | código e evidências de build | apps/gestao |
| Supabase Engineer | contrato de dados aprovado | migration/RPC/RLS e rollback | Supabase |
| Mobile QA | build ou diff estável | matriz executada e defeitos | não |
| iOS/PWA Performance | mudança mobile crítica ou crash | reprodução e análise de performance | não |
| Security Reviewer | diff e modelo de autorização | achados por severidade | não |
| Release Manager | entrega candidata | GO/NO-GO e release notes | não |

## Gates de qualidade

Uma entrega de alto risco só avança quando Produto, Arquitetura, Implementação, QA, Segurança e Release possuem uma conclusão explícita. A ausência de ferramenta ou dispositivo não é aprovação automática: vira risco residual documentado.

## Como pedir a equipe

Exemplos:

- “Use a equipe para planejar esta funcionalidade e espere Produto e Arquitetura antes de implementar.”
- “Investigue este crash com solution_architect e mobile_qa; depois delegue a correção ao flutter_engineer.”
- “Revise este branch com security_reviewer, mobile_qa e release_manager e me dê um GO/NO-GO.”
- “Implemente esta alteração com flutter_gestao_engineer e supabase_engineer, sem que editem os mesmos arquivos.”

O Codex encontra os agentes em `.codex/agents/`. Novas sessões abertas na raiz do repositório carregam também o contrato de trabalho definido em `AGENTS.md`.
