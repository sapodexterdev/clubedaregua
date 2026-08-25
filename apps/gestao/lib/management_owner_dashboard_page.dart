part of 'management.dart';

class _AdminDashboardPage extends StatelessWidget {
  const _AdminDashboardPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey('owner-dashboard-v3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OwnerDashboardIntro(),
        SizedBox(height: CDRSpacingTokens.xxl),
        _SectionTitle(
          'Indicadores planejados',
          eyebrow: 'VISÃO GERAL',
        ),
        SizedBox(height: CDRSpacingTokens.md),
        _OwnerDashboardIndicatorGrid(),
      ],
    );
  }
}

class _OwnerDashboardIntro extends StatelessWidget {
  const _OwnerDashboardIntro();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: CDRCard(
          key: const ValueKey('owner-dashboard-intro'),
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
                  Icons.insights_rounded,
                  color: CDRColorTokens.brandYellow,
                  semanticLabel: 'Indicadores',
                ),
              ),
              const SizedBox(height: CDRSpacingTokens.lg),
              Text(
                'Seus números, com clareza',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: CDRSpacingTokens.sm),
              Text(
                'Estamos preparando indicadores reais da sua barbearia. '
                'Até a integração ser concluída, nenhum valor estimado será exibido aqui.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CDRColorTokens.textSecondary,
                    ),
              ),
              const SizedBox(height: CDRSpacingTokens.lg),
              const _OwnerDashboardStatus(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerDashboardStatus extends StatelessWidget {
  const _OwnerDashboardStatus();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('owner-dashboard-status'),
      label: 'Status: dados em preparação',
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
                  'Dados em preparação',
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

class _OwnerDashboardIndicatorData {
  const _OwnerDashboardIndicatorData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _OwnerDashboardIndicatorGrid extends StatelessWidget {
  const _OwnerDashboardIndicatorGrid();

  static const _indicators = [
    _OwnerDashboardIndicatorData(
      icon: Icons.payments_outlined,
      title: 'Faturamento',
      description: 'Receitas consolidadas por período e forma de pagamento.',
    ),
    _OwnerDashboardIndicatorData(
      icon: Icons.calendar_month_outlined,
      title: 'Agendamentos',
      description: 'Volume de atendimentos e evolução da agenda da equipe.',
    ),
    _OwnerDashboardIndicatorData(
      icon: Icons.content_cut_rounded,
      title: 'Desempenho operacional',
      description:
          'Serviços e profissionais em destaque com dados verificáveis.',
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
          key: const ValueKey('owner-dashboard-indicators'),
          spacing: CDRSpacingTokens.md,
          runSpacing: CDRSpacingTokens.md,
          children: [
            for (final indicator in _indicators)
              SizedBox(
                width: width,
                child: _OwnerDashboardIndicatorCard(data: indicator),
              ),
          ],
        );
      },
    );
  }
}

class _OwnerDashboardIndicatorCard extends StatelessWidget {
  const _OwnerDashboardIndicatorCard({required this.data});

  final _OwnerDashboardIndicatorData data;

  @override
  Widget build(BuildContext context) {
    return CDRCard(
      key: ValueKey('owner-dashboard-indicator-${data.title}'),
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
