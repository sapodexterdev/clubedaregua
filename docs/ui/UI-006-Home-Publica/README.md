# UI-006 — Home Pública

## Objetivo

Ser a principal experiência de descoberta do app Cliente, permitindo explorar
barbearias antes de criar uma conta.

## Status

Aprovada para implementação por blocos.

## Posição no fluxo

`Explorar Barbearias → Home Pública → Perfil da Barbearia → Ver Horários`

## Fonte de verdade

1. `docs/brand/v3/BRAND_FOUNDATIONS.md`;
2. `docs/brand/v3/MOTION_SYSTEM.md`;
3. `spec.md` desta tela;
4. `docs/ux/UX-002-Descobrir-Barbearias/` para regras funcionais.

O board antigo continua como referência de arquitetura da informação. Logo V2,
navalha, Bebas Neue, dourado antigo e valores fixos do mockup não devem ser
copiados para o aplicativo V3.

## Dependências

- serviço de descoberta de barbearias;
- localização atual ou cidade selecionada;
- descoberta real em um raio inicial de 10 km, com permissão explícita;
- busca e filtros funcionais;
- fallback local aprovado para capas;
- Barlow Condensed e Inter empacotadas;
- componentes V3 de card, chip, busca e navegação inferior.

## Estratégia de revisão

A Home será validada em blocos, nesta ordem:

1. cabeçalho, busca e localização;
2. categorias;
3. card grande;
4. cards compactos e seções;
5. estados de carregamento, vazio e erro;
6. navegação inferior e responsividade.

Cada bloco deve ser aprovado antes do próximo.
