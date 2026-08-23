# ADR-001 — Marca V3 como autoridade visual

## Status

Aceito.

## Contexto

O repositório mantém documentos, boards e ativos das versões V1 e V2 para
preservar o histórico do produto. Parte desse material ainda se declarava fonte
visual oficial e entrava em conflito com a Marca V3 aprovada.

## Decisão

A Marca V3 é a única autoridade visual para novas implementações e revisões do
Clube da Régua.

A precedência obrigatória é:

1. `assets/brand/v3/tokens.json` e os SVGs mestres em `assets/brand/v3/`;
2. `docs/brand/v3/BRAND_FOUNDATIONS.md`;
3. `docs/brand/v3/MOTION_SYSTEM.md`;
4. `docs/ui/SHARED_COMPONENTS_V3.md` para componentes compartilhados;
5. a UI Specification V3 aprovada da tela;
6. documentos de experiência e UX para jornada, conteúdo e comportamento;
7. implementação existente, apenas como referência técnica.

`Brand_Kit_v1`, `Brand_Kit_v2`, boards que exibem a identidade antiga e
especificações não migradas permanecem no repositório como histórico. Eles
podem orientar fluxos e arquitetura da informação, mas não cores, tipografia,
logos, iconografia, movimento ou componentes.

Uma UI Specification nunca pode reintroduzir ativos ou estilos V1/V2. Quando a
spec ainda estiver `Em especificação` ou `Em validação` e divergir da V3, a
fundação V3 prevalece e a divergência deve ser corrigida na documentação antes
da implementação.

## Nomenclatura de produto

As áreas profissionais usam os modos **Barbeiro** e **Dono**. O termo
`Administrador` fica reservado a funções técnicas ou de plataforma e não deve
nomear o modo do proprietário da barbearia.

O agendamento do Cliente é confirmado automaticamente após a validação de
disponibilidade e a gravação bem-sucedida. Dono e Barbeiro não precisam aceitar
manualmente cada horário.

## Consequências

- Cliente e Gestão compartilham os mesmos tokens e princípios V3.
- Novas telas não podem copiar Bebas Neue, dourado antigo, navalha ou logos V2
  dos boards históricos.
- Divergências entre documentação e código devem ser registradas e corrigidas
  por ondas, sem redesenhar fluxos funcionais implicitamente.
- Alterações futuras na identidade exigem um novo ADR e atualização conjunta
  dos tokens, fundações e ativos mestres.
