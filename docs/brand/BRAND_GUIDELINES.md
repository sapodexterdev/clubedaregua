# Brand Guidelines - Clube da Régua

> A partir desta versão, toda alteração visual do Clube da Régua deve seguir obrigatoriamente esta documentação e o arquivo Brand_Kit_v2.png. Em caso de conflito entre código existente e documentação da marca, prevalece a documentação da marca.

## Fonte Oficial

A imagem `docs/brand/Brand_Kit_v2.png` é a fonte oficial da identidade visual do Clube da Régua.

A fonte de verdade inclui a prancha oficial e os arquivos mestres em `assets/brand/`. UX Boards anteriores devem ser atualizados quando houver conflito com o Brand Kit V2.

Nenhuma alteração visual deve ser implementada sem consultar:

- `docs/brand/Brand_Kit_v2.png`
- `docs/brand/BRAND_GUIDELINES.md`
- `docs/brand/UI_PRINCIPLES.md`

## Brand Evolution

A identidade visual do Clube da Régua foi refinada e vetorizada a partir da marca aprovada, preservando coroa, lettering urbano e navalha-régua.

O Brand Kit V2 consolida essa evolução e passa a ser a referência oficial para produto, documentação, mockups, telas, componentes e peças visuais.

O arquivo `docs/brand/Brand_Kit_v1.png` fica marcado como legado. Ele pode ser consultado apenas como histórico de evolução da marca, mas não deve orientar novas implementações.

## Elementos Oficiais

Toda documentação e implementação visual deve utilizar exclusivamente:

- Logo oficial disponível em `assets/brand/logos/`.
- Paleta oficial documentada em `docs/brand/COLOR_TOKENS.md`.
- Tipografia oficial documentada em `docs/brand/TYPOGRAPHY.md`.
- Elementos gráficos oficiais presentes em `assets/brand/elements/`.
- Iconografia oficial documentada em `docs/brand/ICONOGRAPHY.md`.

## Marca

Nome oficial: **Clube da Régua**

Slogan oficial:

**Tecnologia que eleva o nível da sua barbearia.**

## Posicionamento Visual

A marca deve transmitir uma barbearia moderna, urbana e premium. A estética combina:

- Preto e grafite como base.
- Amarelo como destaque nobre.
- Grafite, navalha, precisão e rua como referências visuais.
- Sensação de operação profissional e crescimento.

## Regras Obrigatórias

1. A `Brand_Kit_v2.png` é a fonte oficial da identidade visual.
2. Toda UI deve ser dark first.
3. Botões principais devem usar amarelo.
4. Cards devem usar fundo escuro/grafite com borda discreta.
5. Textos devem ter alto contraste e boa legibilidade.
6. O amarelo deve ser usado apenas para ação principal, destaque e status importante.
7. Cliente e Gestão devem parecer parte do mesmo produto.
8. É proibido criar nova paleta, novos estilos visuais ou nova linguagem de UI sem atualizar os documentos da pasta `docs/brand`.
9. Toda nova issue deve começar respeitando `BRAND_GUIDELINES.md`.
10. O Brand Kit V1 é legado e não deve ser usado como referência para novas telas.

## Paleta Oficial

- Preto: `#09090B`
- Grafite: `#18181B`
- Grafite claro: `#27272A`
- Amarelo Régua: `#F3B200`
- Branco: `#FFFFFF`
- Cinza: `#A1A1AA`

## Tipografia

- Títulos: **Barlow Condensed**
- Corpo de texto: **Inter**

## Uso da Marca em Mockups

A logo oficial do Clube da Régua nunca deve ser recriada por IA.

Toda imagem gerada por IA deve conter apenas:

- Cenário.
- Iluminação.
- Composição.
- Espaço reservado para a marca.

A aplicação da identidade visual deverá utilizar exclusivamente os arquivos oficiais presentes em:

`assets/brand/`

Nunca substituir:

- Tipografia.
- Coroa.
- Navalha.
- Proporções.
- Espaçamentos.
- Cores.

A logo oficial deve ser aplicada posteriormente pelo Flutter, Figma ou editor gráfico.

## Aplicação

Toda tela nova, ajuste visual, componente, botão, card, navegação, modal ou estado visual deve seguir esta documentação.

Quando houver conflito entre implementação anterior e a identidade oficial, atualizar a implementação para se alinhar à marca.
