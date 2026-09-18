# Situação atual do projeto

Atualizado em 18/09/2026.

## Estado do branch

- Branch: `codex/unificar-apps`.
- Remoto confirmado em `26f2de1` (`chore: normalizar fim de arquivo da equipe`).
- Os commits anteriores de navegação unificada, identidade visual, agenda responsiva e segurança de clientes estão publicados.
- Existe uma alteração preexistente em `apps/gestao/lib/management_team_page.dart`; ela não faz parte desta onda e deve permanecer fora de commits.

## MVP original

As dez issues originais do MVP estão implementadas no histórico publicado,
incluindo configuração da barbearia, dashboard operacional, disponibilidade e
sprint de qualidade. O tracker antigo estava desatualizado e não refletia o
estado do branch.

O produto também possui entregas posteriores para disponibilidade avançada,
convites de equipe, confirmação automática, vendas, segurança de clientes,
responsividade e onboarding por CEP.

## Arquitetura funcional entregue

O monorepo mantém um único produto Flutter com dois pontos de entrada integrados:

- `apps/cliente`: descoberta pública, agendamento, perfil do cliente e onboarding do Dono.
- `apps/gestao`: navegação profissional compartilhada pelos modos Dono, Barbeiro e funções de gestão.
- `packages/shared`: componentes, tokens e contratos visuais comuns.
- `supabase`: schema, migrations, RPCs, RLS e Storage.

A sessão Supabase é única. A renovação compartilhada de token validada em `c366644f0db1b77e9ac5140d884dca2a4b823520` permanece preservada.

## Segurança de clientes

O commit `c02fb23` consolidou o isolamento da carteira de clientes:

- Barbeiro consulta somente clientes com atendimento concluído atribuído ao próprio perfil, por RPCs `list_barber_customers` e `list_barber_customer_appointments`.
- Dono e Manager mantêm a gestão ampla de clientes.
- Bloqueio de agendamento continua exclusivo do Dono ativo.
- Trocas de modo invalidam cargas antigas, limpam o snapshot anterior e impedem respostas atrasadas de sobrescrever o modo atual.
- A migration `supabase/issue_025_barber_customer_scope.sql` inclui guardrails para impedir cliente, telefone e bloqueio vinculados a outra barbearia.

## Onboarding por CEP

Implementação local pendente de publicação:

- `apps/cliente/lib/services/postal_code_service.dart` consulta o ViaCEP por HTTPS, sem enviar credenciais da sessão Supabase.
- `OwnerOnboardingScreen` oferece CEP opcional, busca automática ao completar oito dígitos, botão de nova busca e preenchimento de rua, bairro, cidade e UF.
- A etapa de localização separa rua, número, complemento e bairro, mantendo a composição do endereço compatível com o RPC atual de onboarding.
- Após concluir o cadastro, o Dono entra diretamente na Configuração da Barbearia para completar os dados operacionais antes de acessar o painel.
- O endereço continua editável para número, complemento e correções manuais.
- CEP inexistente, indisponibilidade, timeout, troca rápida de CEP, edição manual e saída da tela possuem tratamento próprio.
- Um CEP que retorna apenas cidade e UF limpa o logradouro preenchido anteriormente para evitar endereço misturado.

## Configuração da barbearia

- O formulário de configuração reaproveita o endereço do onboarding e exibe
  rua, número, complemento, bairro e CEP em campos separados.
- Ao salvar, os componentes continuam sendo compostos no formato compatível
  com o campo de endereço já existente.
- Os botões de upload da logo e da foto de capa ficam alinhados aos respectivos
  campos de URL, preservando a leitura do formulário em telas estreitas.

## Perfil público da barbearia

- Os botões de telefone, WhatsApp, Instagram e endereço permanecem visíveis no
  perfil público, mas ficam desabilitados quando o dado correspondente não foi
  cadastrado.
- O perfil informa ao cliente quando ainda existem dados de contato pendentes.

Arquivos locais dessa alteração:

- `apps/cliente/lib/screens/owner_onboarding_screen.dart`
- `apps/cliente/lib/services/postal_code_service.dart`
- `apps/cliente/test/services/postal_code_service_test.dart`
- `apps/cliente/test/design/owner_onboarding_postal_code_test.dart`

## Validação

Validações executadas para a alteração de CEP:

- Dart format: aprovado.
- `git diff --check`: aprovado.
- Testes do serviço: 7 aprovados.
- Testes da tela: 7 aprovados.
- Compilação web de `apps/cliente/lib/main.dart` via `dart2js`: concluída com sucesso.
- Safari/iPhone real: ainda pendente de validação manual.

O comando padrão `flutter test` apresentou bloqueios intermitentes do ambiente Windows ao criar subprocessos. Os mesmos testes foram executados com o `frontend_server` e `flutter_tester`, com resultado aprovado.

## Próxima ação de release

Revisar o diff, validar a nova divisão dos campos de endereço na Vercel e enviar a documentação e a melhoria para `main`. Depois, validar o onboarding instalado no Safari do iPhone, incluindo CEP válido, CEP inexistente, CEP genérico e preenchimento manual.
