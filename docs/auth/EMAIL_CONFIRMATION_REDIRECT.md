# Redirecionamento de confirmação de e-mail

## Comportamento esperado

- cadastro e recuperação enviam `redirect_to` para a origem pública atual;
- o caminho de retorno é sempre `/`, nunca `/gestao/`;
- o app consome `access_token` e `refresh_token` do fragmento;
- a sessão é persistida e os tokens são removidos da URL;
- o retorno funciona tanto na produção quanto em Preview autorizado.

## Configuração obrigatória no Supabase

Em **Authentication → URL Configuration**:

- Site URL: `https://clubedaregua.vercel.app/`
- Redirect URLs:
  - `https://clubedaregua.vercel.app/**`
  - `https://*.vercel.app/**`

Se houver domínio próprio, adicionar também `https://dominio-do-app/**`.

O painel de gestão não deve ser usado como Site URL do projeto de autenticação do cliente.
