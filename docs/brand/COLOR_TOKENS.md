# Color Tokens - Clube da Régua

## Fonte Oficial

Os valores abaixo permanecem compatíveis com a paleta aprovada, mas a fonte
canônica vigente é `assets/brand/v3/tokens.json`, conforme
`ADR-001-V3-AUTORIDADE-VISUAL.md`. Brand Kit V2 e boards antigos são históricos.

## Paleta Oficial

| Token | Hex | Uso |
| --- | --- | --- |
| `black` | `#050505` | Preto Marca, ícone e superfícies institucionais |
| `night` | `#09090B` | Fundo principal dark first |
| `graphite` | `#18181B` | Cards, barras e blocos principais |
| `graphiteLight` | `#27272A` | Superfícies elevadas e campos |
| `brandYellow` | `#F3B200` | Ação principal, destaque e status importante |
| `white` | `#FFFFFF` | Texto principal sobre fundo escuro |
| `gray` | `#A1A1AA` | Texto secundário |
| `border` | `#3F3F46` | Bordas e divisores discretos |

## Regras de Uso

- O fundo principal deve priorizar `night`.
- Cards devem usar `graphite` ou `graphiteLight`.
- `brandYellow` não deve ser usado como cor dominante.
- `white` deve garantir leitura em áreas escuras.
- `gray` deve ser usado para informação secundária, nunca para texto essencial sem contraste adequado.

## Proibições

- Não criar nova paleta sem atualizar `docs/brand/`.
- Não trocar o Amarelo Régua por laranja, amarelo neon ou tons genéricos.

O identificador `gold` permanece temporariamente no código como alias de compatibilidade para componentes anteriores ao Brand Kit V2.
- Não usar telas majoritariamente claras sem justificativa aprovada na documentação.
