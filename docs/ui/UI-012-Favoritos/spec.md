# Spec — UI-012 Favoritos

## Estrutura

1. título `Favoritos`;
2. lista de cards com capa, nome, localização, status e faixa de preço;
3. ação de remover em cada card;
4. navegação inferior oficial.

## Regras funcionais

- apenas usuários autenticados podem favoritar;
- o perfil exibe coração preenchido quando salvo;
- login retorna ao perfil que originou a ação;
- atualização usa token autenticado e RLS por `client_id`;
- pull-to-refresh reconcilia o estado com o banco;
- falha não altera visualmente o estado persistido.
