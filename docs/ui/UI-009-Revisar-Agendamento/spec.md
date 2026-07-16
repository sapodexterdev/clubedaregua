# Spec — UI-009 Revisar Agendamento

## Estrutura

1. título e orientação curta;
2. resumo com barbearia, data, horário, duração, serviço, profissional e valor;
3. autenticação quando o visitante ainda não estiver conectado;
4. nome e WhatsApp para usuário autenticado;
5. preferência de pagamento;
6. aviso sobre confirmação pela barbearia;
7. CTA fixo de autenticação ou envio.

## Regras funcionais

- nome deve ter ao menos três caracteres;
- WhatsApp deve conter DDD e nove dígitos;
- envio revalida a disponibilidade do horário;
- impedir envios duplicados enquanto a solicitação estiver em andamento;
- login e cadastro retornam para esta tela;
- falha não apaga os dados preenchidos;
- sucesso abre a tela de solicitação enviada.

## Linguagem

- usar `solicitação`, nunca prometer reserva confirmada;
- informar que o pagamento ocorre diretamente com a barbearia;
- usar amarelo somente no resumo temporal, seleção e CTA.
