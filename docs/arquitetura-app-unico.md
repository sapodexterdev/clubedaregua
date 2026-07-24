# Arquitetura do App Único

## Decisão

O Clube da Régua será distribuído como um único produto. Cliente, barbeiro,
recepção, gerente e proprietário usam a mesma conta e a mesma sessão.

As experiências continuam separadas internamente em três modos:

- **Modo Cliente:** descoberta, favoritos, agendamento, agenda e perfil.
- **Modo Barbeiro:** agenda, solicitações, clientes e comissão.
- **Modo Dono:** serviços, equipe, configuração e indicadores.

## Resolução de acesso

Após autenticar, o app consulta:

- os vínculos ativos em `shop_members`;
- as barbearias cujo `owner_id` pertence ao usuário;
- o cadastro ativo em `barbers` vinculado ao `user_id`;
- o papel global `admin`, quando aplicável.

Cliente é o modo base de toda conta. O Modo Barbeiro só é liberado para um
profissional ativo. O Modo Dono só é liberado para proprietário, gerente ou
administrador da plataforma.

Quem possui apenas o modo Cliente segue diretamente para a Home. Quem acumula
papéis visualiza somente os modos realmente autorizados.

O banco continua sendo a autoridade de autorização por meio de RLS. A escolha
de modo altera apenas a navegação e nunca concede permissões.

## Migração progressiva

1. Compartilhar sessão e resolver os modos disponíveis.
2. Manter `/gestao/` como módulo profissional durante a transição.
3. Incorporar as áreas profissionais ao shell único por módulos.
4. Remover a autenticação duplicada.
5. Desativar o build separado somente após validação funcional completa.

## Regra de produto

Usuários com mais de um papel podem trocar de modo pelo Perfil. O último modo
utilizado é lembrado nos acessos seguintes. Um dono que também atende clientes
recebe os modos Cliente, Barbeiro e Dono.

A escolha de modo nunca concede autorização. As permissões continuam
determinadas pelos vínculos do banco e protegidas pelas políticas RLS. Sair da
conta encerra a sessão em todos os modos.
