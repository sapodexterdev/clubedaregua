# Spec — UI-013 Perfil do cliente

## Estrutura

1. identificação com inicial, nome, e-mail e WhatsApp;
2. edição de nome e WhatsApp em painel inferior;
3. envio do link de recuperação de senha;
4. atalhos para agenda e favoritos;
5. saída da conta com confirmação;
6. navegação inferior oficial.

## Regras funcionais

- o perfil só consulta a linha cujo `user_id` corresponde ao usuário autenticado;
- nome e telefone são persistidos em `public.profiles`;
- o e-mail é apenas exibido, pois pertence à autenticação;
- falhas de leitura e gravação são exibidas sem substituir os dados atuais;
- ao sair, agenda e favoritos privados são removidos do estado local.
