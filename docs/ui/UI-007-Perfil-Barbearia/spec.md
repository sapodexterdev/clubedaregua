# Spec — UI-007 Perfil da Barbearia

## Status

Em validação no Preview.

## Estrutura

1. capa real da barbearia com retorno sobreposto;
2. logo, nome e localização;
3. avaliação real ou estado `Nova no Clube`;
4. status e horário de funcionamento;
5. distância apenas quando a localização do dispositivo estiver disponível;
6. resumo de funcionamento e faixa real de preços;
7. descrição factual gerada a partir dos dados cadastrados;
8. contatos e endereço somente quando informados;
9. serviços reais e selecionáveis;
10. profissionais reais e selecionáveis;
11. CTA fixo `Ver horários disponíveis`.

## Regras de conteúdo

- não exibir contagem de avaliações quando for zero;
- não criar galeria com imagens genéricas;
- não afirmar disponibilidade quando não houver serviço e profissional;
- preservar a seleção válida de serviço e profissional;
- usar fallback visual da marca apenas se capa ou logo falharem;
- contatos copiam o valor cadastrado e confirmam a ação ao usuário.

## Tokens

- fundo: `AppColors.background`;
- superfície: `AppColors.card`;
- borda: `AppColors.stroke`;
- ação: `AppColors.orange`;
- títulos: Barlow Condensed;
- corpo: tipografia padrão do aplicativo.

## Responsividade e acessibilidade

- conteúdo ocupa a largura do frame móvel até 430 px;
- CTA respeita a área segura inferior;
- textos longos usam limite e reticências quando necessário;
- ações possuem rótulos semânticos e área de toque adequada.
