# Spec — UI-001 Splash V3

## Resultado de produto

A abertura comunica a marca com rapidez e conduz ao destino correto sem flash,
reload, autenticação duplicada ou nova inicialização durante o uso.

## Conteúdo aprovado

- assinatura: `brand_v3_logo_principal.svg`;
- slogan: `O SISTEMA FEITO PARA BARBEARIAS.`;
- `BARBEARIAS.` em Amarelo Régua;
- carga acima de dois segundos: `CARREGANDO...` com ponto amarelo estático.

Não usar fotografia, navalha, segunda logo, glow contínuo ou texto técnico.

## Composição

- fundo Preto Marca `#050505`;
- assinatura principal centralizada;
- largura de `76%`, limitada a `260–420 px` quando houver espaço;
- conjunto limitado a `480 px` em tablet e desktop;
- slogan `24 px` abaixo da assinatura;
- margem protegida de `24 px` e `SafeArea` obrigatória;
- Web acima de `520 px` preserva o frame móvel de `430 px`.

## Tipografia

- slogan em Inter `700`, `11/15.4`, tracking `2.2 px`, caixa alta;
- mensagem de carga em Inter `600`, `11/15.4`, tracking `1.4 px`;
- lettering permanece no SVG oficial e nunca é reconstruído com fonte.

## Movimento

- cena completa normal: no máximo `2000 ms`;
- assinatura: entrada única por fade e escala `0.96 → 1`;
- slogan: entrada única por fade;
- saída: fade de `240 ms`;
- não repetir, pulsar ou manter ticker decorativo;
- navegação e leitura não dependem da animação;
- após `2000 ms`, a marca permanece estática e surge o indicador separado.

Com redução de movimento, remover escala e deslocamento, usar fade de entrada
de `200 ms` e saída de `150 ms`, e manter todo o restante estático.

## Responsividade Web/PWA

- viewport usa `viewport-fit=cover`;
- altura dinâmica usa `100dvh` quando suportada;
- paddings consideram `safe-area-inset-*`;
- o modo instalado usa status bar preta no iPhone;
- o boot carrega a fonte Inter empacotada, sem depender da rede;
- tema e manifesto usam `#050505` para evitar cintilação;
- `prefers-reduced-motion` aplica o mesmo contrato do Flutter.

## Boot e navegação

Existe uma única decisão inicial, preservada na ordem atual:

1. recuperação de senha pendente;
2. convite de equipe;
3. Onboarding ainda não concluído;
4. Home pública/Cliente ou último modo profissional permitido.

O Flutter é o dono da retirada normal do boot HTML e a solicita após navegar
para o destino. A função Web é idempotente. Após 30 segundos sem o sinal, o
próprio boot substitui o loading por um erro acessível e a ação `TENTAR
NOVAMENTE`; o retry é a única ação que recarrega a página e depende de gesto
explícito. `hashchange`, observadores do DOM e troca de modo não removem nem
recriam a Splash.

## Sessão e lifecycle

- uma única árvore Flutter, `AppState`, `AppModeController` e sessão Supabase;
- a cena só existe no cold start/reload integral do processo;
- background/resume e Cliente ↔ Barbeiro ↔ Dono não navegam para `/`;
- nenhum listener de autenticação, refresh de token ou bootstrap adicional é
  criado pela Splash;
- preservar a renovação compartilhada validada em `c366644f`.

## Acessibilidade

- assinatura expõe o nome `Clube da Régua` uma única vez;
- carga longa é anunciada como atualização de estado;
- não há informação transmitida somente por cor;
- o conjunto cabe em `360 × 640 px`, `390 × 844 px`, texto ampliado e desktop;
- nenhuma animação infinita permanece ativa.

## Critérios de aceite

- [ ] assinatura principal e slogan oficiais em `#050505`;
- [ ] zero fotografia, blur, glow contínuo, `repeat` ou animação CSS infinita;
- [ ] cena finita em até dois segundos e estado lento estático;
- [ ] reduced motion respeitado no Flutter e no CSS;
- [ ] Web não precacheia nem decodifica a antiga fotografia Flutter;
- [ ] boot HTML é retirado uma única vez após o frame do destino;
- [ ] falha do runtime termina em erro legível com retry, nunca loading eterno;
- [ ] recovery, convite, primeiro acesso, Cliente, Barbeiro e Dono mantêm suas
      rotas e a mesma sessão;
- [ ] troca de modo e retorno do background não reabrem a Splash;
- [ ] sem flash branco/preto entre boot e destino;
- [ ] Safari, PWA instalado no iPhone e desktop fazem parte do gate manual.
