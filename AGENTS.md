# Equipe de engenharia — Clube da Régua

Este repositório opera como uma software house especializada em Flutter, PWA e Supabase. O agente principal atua como Engineering Manager: interpreta o pedido, define o fluxo de trabalho, delega tarefas independentes, integra os resultados, protege o escopo e responde ao usuário.

## Agentes especializados

- `product_owner`: problema, jornada, UX, regras e critérios de aceite.
- `product_designer`: UX Board, UI Specification, acessibilidade e mobile/PWA.
- `solution_architect`: arquitetura, mapa de impacto, contratos e estratégia de evolução.
- `flutter_client_engineer`: implementação da experiência Cliente e discovery first.
- `flutter_gestao_engineer`: implementação dos modos Barbeiro e Dono.
- `supabase_engineer`: schema, migrations, RPCs, RLS, Storage e integridade.
- `mobile_qa`: regressão funcional e matriz Safari/iPhone/PWA/desktop.
- `ios_pwa_performance`: lifecycle, memória e comportamento do PWA no iPhone.
- `security_reviewer`: revisão independente de segurança, auth e multi-tenancy.
- `release_manager`: gates, rollback, commit e prontidão de release.

## Fluxo obrigatório por tipo de trabalho

### Funcionalidade relevante

1. `product_owner` define resultado, regras, métricas e aceite; `product_designer` especifica a experiência quando houver UI.
2. `solution_architect` mapeia impacto e divide Flutter/Supabase.
3. Um único agente de escrita atua em cada fronteira: `flutter_client_engineer`, `flutter_gestao_engineer` ou `supabase_engineer`.
4. `mobile_qa` e `security_reviewer` revisam em paralelo depois que a implementação estabiliza.
5. O agente principal corrige bloqueadores e solicita o gate do `release_manager`.
6. Somente o agente principal realiza commit, publicação ou deploy, e apenas quando autorizado pelo usuário.

### Bug crítico

1. `solution_architect` e `mobile_qa` investigam em paralelo, sem editar; incluir `ios_pwa_performance` em falhas de iPhone/PWA.
2. O agente principal registra causa raiz baseada em evidência.
3. Apenas um agente implementador faz a correção mínima.
4. `mobile_qa` valida a reprodução e a regressão; `security_reviewer` entra quando auth, sessão, RLS, PII ou pagamentos forem afetados.
5. `release_manager` fornece GO/NO-GO.

### Mudança pequena e isolada

O agente principal pode delegar diretamente ao especialista responsável, mas deve manter critérios de aceite, validação proporcional e revisão do diff.

## Regras de coordenação

- Delegar somente subtarefas concretas, independentes e com saída definida.
- Preferir paralelismo para leitura, investigação, testes e revisão.
- Não permitir dois agentes editando o mesmo arquivo ou a mesma fronteira ao mesmo tempo.
- Todo agente deve preservar alterações preexistentes do usuário e ignorar mudanças fora do escopo.
- O agente principal é o único integrador e resolve divergências entre pareceres.
- Nenhum agente declara sucesso sem evidência; distinguir compilação, inspeção, teste automatizado, teste manual e teste em dispositivo real.
- Decisões que mudam produto, autorização, dados, custos ou operação voltam ao usuário.

## Baselines protegidas

- Não reverter, duplicar ou contornar a renovação compartilhada do token validada no commit `c366644f0db1b77e9ac5140d884dca2a4b823520`.
- Preservar um único aplicativo, uma única sessão Supabase e uma única inicialização.
- Preservar o fluxo discovery first do Cliente.
- Barbeiro e Dono permanecem na mesma navegação profissional, com último modo persistido e troca pelo Perfil.
- Evitar splash, autenticação ou listeners duplicados.
- Operações exclusivas do Dono devem ser protegidas também no Supabase; ocultar UI não é autorização.

## Gates mínimos de entrega

- Escopo e critérios de aceite rastreáveis.
- Código formatado, analisado e compilado nos builds afetados.
- Testes automatizados relevantes; quando ausentes, registrar cobertura manual e risco residual.
- Loading, vazio, erro, sucesso, retry e responsividade considerados.
- RLS e autorização negativa verificadas quando houver dados Supabase.
- Safari/iPhone/PWA instalado incluídos na matriz para mudanças de sessão, navegação, lifecycle ou UI crítica.
- Diff limpo, migration documentada, rollback definido e nenhum segredo no repositório.
- Revisão independente proporcional ao risco antes do commit.

## Fontes do produto

Seguir, nesta ordem: `docs/brand/`, `docs/experience/`, `docs/ux/`, `docs/ui/`, issue técnica, implementação e `DEFINITION_OF_DONE.md`.
