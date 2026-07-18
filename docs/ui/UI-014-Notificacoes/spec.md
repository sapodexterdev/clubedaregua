# Spec — UI-014 Notificações

## Estrutura

1. sino funcional na Home com contador;
2. lista cronológica de notificações;
3. diferenciação visual entre lidas e não lidas;
4. ação individual de leitura;
5. ação `Ler todas`;
6. atualização por gesto.

## Regras funcionais

- somente usuários autenticados acessam a central;
- a consulta e atualização usam o token autenticado;
- a RLS limita o acesso a linhas do próprio `user_id`;
- falhas não alteram localmente o estado de leitura;
- sem registros, a tela apresenta um estado vazio neutro.
