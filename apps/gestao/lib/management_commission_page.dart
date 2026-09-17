part of 'management.dart';

class _CommissionPage extends StatelessWidget {
  const _CommissionPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey('commission-page-v3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommissionIntro(),
        SizedBox(height: CDRSpacingTokens.xxl),
        _SectionTitle(
          'Indicadores planejados',
          eyebrow: 'COMISSÃO',
        ),
        SizedBox(height: CDRSpacingTokens.md),
        _CommissionIndicatorGrid(),
      ],
    );
  }
}

class _CommissionIntro extends StatelessWidget {
  const _CommissionIntro();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: CDRCard(
          key: const ValueKey('commission-intro'),
          padding: const EdgeInsets.all(CDRSpacingTokens.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: CDRSizeTokens.touchTarget,
                height: CDRSizeTokens.touchTarget,
                decoration: BoxDecoration(
                  color: const Color(0x1FF3B200),
                  borderRadius: BorderRadius.circular(CDRRadiusTokens.medium),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: CDRColorTokens.brandYellow,
                  semanticLabel: 'Comissão',
                ),
              ),
              const SizedBox(height: CDRSpacingTokens.lg),
              Text(
                'Sua comissão, sem estimativas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: CDRSpacingTokens.sm),
              Text(
                'Estamos preparando o cálculo com base nos atendimentos '
                'concluídos e no percentual definido pela barbearia. Até a '
                'integração ser concluída, nenhum valor estimado será exibido aqui.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CDRColorTokens.textSecondary,
                    ),
              ),
              const SizedBox(height: CDRSpacingTokens.lg),
              const _CommissionStatus(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommissionStatus extends StatelessWidget {
  const _CommissionStatus();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('commission-status'),
      label: 'Status: dados de comissão em preparação',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CDRSpacingTokens.md,
            vertical: CDRSpacingTokens.sm,
          ),
          decoration: BoxDecoration(
            color: CDRColorTokens.graphiteLight,
            borderRadius: BorderRadius.circular(CDRRadiusTokens.pill),
            border: Border.all(color: CDRColorTokens.border),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: CDRSizeTokens.icon,
                color: CDRColorTokens.brandYellow,
              ),
              SizedBox(width: CDRSpacingTokens.sm),
              Flexible(
                child: Text(
                  'Dados de comissão em preparação',
                  style: CDRTypographyTokens.label,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommissionIndicatorData {
  const _CommissionIndicatorData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _CommissionIndicatorGrid extends StatelessWidget {
  const _CommissionIndicatorGrid();

  static const _indicators = [
    _CommissionIndicatorData(
      icon: Icons.payments_outlined,
      title: 'Produção do período',
      description: 'Total dos atendimentos elegíveis no período selecionado.',
    ),
    _CommissionIndicatorData(
      icon: Icons.percent_rounded,
      title: 'Percentual aplicado',
      description: 'Taxa de comissão registrada para cada atendimento.',
    ),
    _CommissionIndicatorData(
      icon: Icons.event_available_outlined,
      title: 'Repasse previsto',
      description: 'Valor devido e situação do próximo repasse.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 && textScale <= 1.5
            ? 3
            : constraints.maxWidth >= 600
                ? 2
                : 1;
        final width =
            (constraints.maxWidth - ((columns - 1) * CDRSpacingTokens.md)) /
                columns;
        return Wrap(
          key: const ValueKey('commission-indicators'),
          spacing: CDRSpacingTokens.md,
          runSpacing: CDRSpacingTokens.md,
          children: [
            for (final indicator in _indicators)
              SizedBox(
                width: width,
                child: _CommissionIndicatorCard(data: indicator),
              ),
          ],
        );
      },
    );
  }
}

class _CommissionIndicatorCard extends StatelessWidget {
  const _CommissionIndicatorCard({required this.data});

  final _CommissionIndicatorData data;

  @override
  Widget build(BuildContext context) {
    return CDRCard(
      key: ValueKey('commission-indicator-${data.title}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: _IconBadge(data.icon)),
          const SizedBox(height: CDRSpacingTokens.lg),
          Text(data.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: CDRSpacingTokens.sm),
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CDRColorTokens.textSecondary,
                ),
          ),
          const SizedBox(height: CDRSpacingTokens.lg),
          Text(
            'INDISPONÍVEL POR ENQUANTO',
            style: CDRTypographyTokens.overline.copyWith(
              color: CDRColorTokens.brandYellow,
            ),
          ),
        ],
      ),
    );
  }
}
