part of 'management.dart';

class _CommissionPage extends StatelessWidget {
  const _CommissionPage();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ManagementSession>();
    final metrics = session.commissionMetrics;
    final period = switch (session.commissionDays) {
      1 => 'HOJE',
      30 => 'ÚLTIMOS 30 DIAS',
      _ => 'ÚLTIMOS 7 DIAS',
    };

    return Column(
      key: const ValueKey('commission-page-v3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: CDRSpacingTokens.sm),
        Text(
          'COMISSÃO',
          style: CDRTypographyTokens.overline
              .copyWith(color: CDRColorTokens.brandYellow),
        ),
        const SizedBox(height: CDRSpacingTokens.sm),
        Text(
          'Sua comissão, com clareza',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: CDRSpacingTokens.md),
        Wrap(
          spacing: CDRSpacingTokens.sm,
          runSpacing: CDRSpacingTokens.sm,
          children: [
            _CommissionPeriodChip(
              label: 'Hoje',
              days: 1,
              selected: session.commissionDays == 1,
            ),
            _CommissionPeriodChip(
              label: '7 dias',
              days: 7,
              selected: session.commissionDays == 7,
            ),
            _CommissionPeriodChip(
              label: '30 dias',
              days: 30,
              selected: session.commissionDays == 30,
            ),
          ],
        ),
        const SizedBox(height: CDRSpacingTokens.md),
        Text(
          period,
          style: CDRTypographyTokens.overline
              .copyWith(color: CDRColorTokens.textSecondary),
        ),
        const SizedBox(height: CDRSpacingTokens.sm),
        if (session.isCommissionLoading && metrics == null)
          const _CommissionStateCard(
            icon: Icons.hourglass_top_rounded,
            title: 'Carregando sua comissão',
            message: 'Buscando os atendimentos concluídos no período.',
            child: CircularProgressIndicator(
              color: CDRColorTokens.brandYellow,
            ),
          )
        else if (session.isCommissionLoading && metrics != null)
          const Padding(
            padding: EdgeInsets.only(bottom: CDRSpacingTokens.sm),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: CDRColorTokens.brandYellow,
              backgroundColor: CDRColorTokens.graphiteLight,
            ),
          ),
        if (!session.isCommissionLoading && session.commissionError != null)
          _CommissionStateCard(
            icon: Icons.cloud_off_outlined,
            title: 'Não foi possível carregar a comissão',
            message: session.commissionError!,
            child: TextButton.icon(
              onPressed: session.isCommissionLoading
                  ? null
                  : () => session.fetchCommissionMetrics(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          )
        else if (!session.isCommissionLoading &&
            session.commissionError == null &&
            metrics != null &&
            metrics.completedAppointments == 0)
          const _CommissionStateCard(
            icon: Icons.event_available_outlined,
            title: 'Nenhum atendimento concluído',
            message: 'Quando você concluir atendimentos, sua produção e '
                'comissão aparecerão aqui.',
          ),
        if (!session.isCommissionLoading &&
            session.commissionError == null &&
            metrics != null) ...[
          const SizedBox(height: CDRSpacingTokens.md),
          _CommissionIndicatorGrid(metrics: metrics),
          const SizedBox(height: CDRSpacingTokens.md),
          Text(
            'Cálculo pela data de conclusão. A taxa atual da barbearia é '
            'aplicada a todo o período; se ela mudar, o histórico poderá variar. '
            'Atendimentos antigos usam a última data de alteração disponível. '
            'Pagamentos e repasses ainda não são controlados nesta tela.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CDRColorTokens.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}

class _CommissionPeriodChip extends StatelessWidget {
  const _CommissionPeriodChip({
    required this.label,
    required this.days,
    required this.selected,
  });

  final String label;
  final int days;
  final bool selected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: selected
            ? null
            : (_) => context.read<ManagementSession>().fetchCommissionMetrics(
                  days: days,
                ),
      );
}

class _CommissionStateCard extends StatelessWidget {
  const _CommissionStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.child,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CDRCard(
        key: const ValueKey('commission-state'),
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
              child: Icon(icon, color: CDRColorTokens.brandYellow),
            ),
            const SizedBox(height: CDRSpacingTokens.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: CDRSpacingTokens.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CDRColorTokens.textSecondary,
                  ),
            ),
            if (child != null) ...[
              const SizedBox(height: CDRSpacingTokens.lg),
              child!,
            ],
          ],
        ),
      );
}

class _CommissionIndicatorData {
  const _CommissionIndicatorData({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;
}

class _CommissionIndicatorGrid extends StatelessWidget {
  const _CommissionIndicatorGrid({required this.metrics});

  final CommissionMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final indicators = [
      _CommissionIndicatorData(
        icon: Icons.payments_outlined,
        title: 'Produção do período',
        value: _commissionMoney(metrics.production),
        description: '${metrics.completedAppointments} atendimentos concluídos',
      ),
      _CommissionIndicatorData(
        icon: Icons.percent_rounded,
        title: 'Percentual aplicado',
        value: '${_commissionPercent(metrics.commissionPercent)}%',
        description: 'Percentual atual cadastrado pela barbearia.',
      ),
      _CommissionIndicatorData(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Comissão calculada',
        value: _commissionMoney(metrics.commission),
        description: 'Produção concluída × percentual atual.',
      ),
    ];

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
            for (final indicator in indicators)
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
          Text(data.value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

String _commissionMoney(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

String _commissionPercent(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceAll('.', ',');
