part of 'management.dart';

class _AdminDashboardPage extends StatelessWidget {
  const _AdminDashboardPage();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ManagementSession>();
    final now = DateTime.now();
    final key =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final requests = session.bookingRequests
        .where((item) => item.date == key && item.status != 'cancelled')
        .toList();
    final confirmed = requests
        .where((item) =>
            item.status == 'confirmed' ||
            item.status == 'converted' ||
            item.status == 'completed')
        .length;
    final projected = requests.fold<double>(0, (sum, item) => sum + item.total);
    final realized = requests
            .where((item) => item.status == 'completed')
            .fold<double>(0, (sum, item) => sum + item.total) +
        session.productSalesTodayTotal;
    final double average = confirmed == 0 ? 0 : projected / confirmed;
    final metrics = session.dashboardMetrics;
    final appointmentCount = metrics?.appointments ?? requests.length;
    final confirmedCount = metrics?.confirmedAppointments ?? confirmed;
    final projectedValue = metrics?.projectedRevenue ?? projected;
    final realizedValue = metrics?.realizedRevenue ?? realized;
    final averageValue = metrics?.averageTicket ?? average;

    return Column(
      key: const ValueKey('owner-dashboard-v4'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: CDRSpacingTokens.sm),
        Text('RESUMO DE HOJE',
            style: CDRTypographyTokens.overline
                .copyWith(color: CDRColorTokens.brandYellow)),
        const SizedBox(height: CDRSpacingTokens.sm),
        Text('Seus números, com clareza',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: CDRSpacingTokens.md),
        _DashboardMetricGrid(metrics: [
          _DashboardMetric('Agendamentos', '$appointmentCount',
              Icons.calendar_month_outlined),
          _DashboardMetric(
              'Confirmados', '$confirmedCount', Icons.check_circle_outline),
          _DashboardMetric(
              'Previsto', _money(projectedValue), Icons.trending_up_rounded),
          _DashboardMetric(
              'Realizado', _money(realizedValue), Icons.payments_outlined),
        ]),
        const SizedBox(height: CDRSpacingTokens.lg),
        CDRCard(
            child: Row(children: [
          const _IconBadge(Icons.receipt_long_outlined),
          const SizedBox(width: CDRSpacingTokens.md),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Ticket médio previsto',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: CDRSpacingTokens.xs),
                Text(_money(averageValue),
                    style: Theme.of(context).textTheme.headlineSmall),
                Text('Agendamentos confirmados de hoje',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: CDRColorTokens.textSecondary)),
              ])),
        ])),
        const SizedBox(height: CDRSpacingTokens.xxl),
        const _SectionTitle('Acompanhe a operação', eyebrow: 'PRÓXIMOS PASSOS'),
        const SizedBox(height: CDRSpacingTokens.md),
        _DashboardEmptyState(
          icon: Icons.insights_outlined,
          title: requests.isEmpty ? 'Agenda livre hoje' : 'Agenda em andamento',
          message: requests.isEmpty
              ? 'Quando novos agendamentos forem criados, eles aparecerão aqui.'
              : 'Os indicadores são atualizados a partir dos dados reais da sua barbearia.',
        ),
      ],
    );
  }

  static String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

class _DashboardMetric {
  const _DashboardMetric(this.title, this.value, this.icon);
  final String title;
  final String value;
  final IconData icon;
}

class _DashboardMetricGrid extends StatelessWidget {
  const _DashboardMetricGrid({required this.metrics});
  final List<_DashboardMetric> metrics;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 2 : 1;
        final width =
            (constraints.maxWidth - (columns - 1) * CDRSpacingTokens.md) /
                columns;
        return Wrap(
            spacing: CDRSpacingTokens.md,
            runSpacing: CDRSpacingTokens.md,
            children: [
              for (final metric in metrics)
                SizedBox(
                    width: width,
                    child: CDRCard(
                        child: Row(children: [
                      _IconBadge(metric.icon),
                      const SizedBox(width: CDRSpacingTokens.md),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(metric.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: CDRColorTokens.textSecondary)),
                            const SizedBox(height: CDRSpacingTokens.xs),
                            Text(metric.value,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                          ])),
                    ]))),
            ]);
      });
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState(
      {required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => CDRCard(
          child: Row(children: [
        _IconBadge(icon),
        const SizedBox(width: CDRSpacingTokens.md),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: CDRSpacingTokens.xs),
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: CDRColorTokens.textSecondary)),
        ])),
      ]));
}
