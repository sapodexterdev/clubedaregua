# Fluxo — UX-002 Descobrir Barbearias

## Fluxo Completo

Home Publica

↓

Filtros e Busca

↓

Lista de Barbearias

↓

Perfil da Barbearia

↓

Ver Horarios

↓

Continuar para agendar

## Descricao das Etapas

### 1. Home Publica

Tela inicial de descoberta com saudacao, pergunta principal, campo de busca, localizacao atual, categorias e secoes de barbearias recomendadas.

### 2. Filtros e Busca

Permite refinar os resultados por localizacao, distancia, avaliacao minima, horario de funcionamento, servicos e faixa de preco.

### 3. Lista de Barbearias

Mostra barbearias ordenadas por relevancia, proximidade, avaliacao e disponibilidade. Cada card deve conter imagem, nome, nota, avaliacoes, distancia, status e horario.

### 4. Perfil da Barbearia

Exibe banner, logo, nota, avaliacoes, distancia, horario de funcionamento, canais de contato, sobre, servicos, profissionais, fotos e avaliacoes.

### 5. Ver Horarios

Mostra servico escolhido, dias disponiveis, chips de data e horarios livres. O usuario pode selecionar horario e continuar para agendar.

## Regras do Fluxo

- Geolocalizacao deve ser usada para ordenar por proximidade quando disponivel.
- Busca deve aceitar nome da barbearia, servico e bairro.
- Filtros devem atualizar a lista com feedback visual.
- O perfil deve ter CTA fixo ou sempre visivel para ver horarios.
- O fluxo de autenticacao so deve interromper a jornada quando o usuario confirmar uma acao protegida.

## Estados Previstos

- Carregando resultados.
- Lista vazia.
- Erro de carregamento.
- Sem internet.
- Horario selecionado.
- Nenhum horario disponivel.
