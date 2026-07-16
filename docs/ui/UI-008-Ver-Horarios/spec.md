# Spec — UI-008 Ver Horários

## Estrutura

1. contexto compacto da barbearia;
2. seleção de serviço real;
3. seleção de profissional real;
4. faixa de datas dentro da antecedência configurada;
5. horários livres retornados pela agenda;
6. resumo da seleção;
7. CTA fixo `Continuar`.

## Regras funcionais

- trocar serviço, profissional ou data refaz a consulta;
- limpar horários e seleção enquanto a consulta estiver carregando;
- serviço deve pertencer à barbearia e ser atendido pelo profissional;
- CTA só fica ativo com as quatro escolhas válidas;
- erro de consulta oferece nova tentativa;
- ausência legítima de horário não é exibida como erro;
- autenticação só é exigida na etapa de confirmação.

## Visual

- fundo preto, superfícies grafite e bordas discretas;
- amarelo apenas em passos, seleções e CTA;
- título em Barlow Condensed;
- controles com raio entre 14 e 16 px;
- CTA respeita a área segura inferior.
