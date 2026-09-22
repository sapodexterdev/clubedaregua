part of 'management.dart';

class _AdminDashboardPage extends StatelessWidget {
  const _AdminDashboardPage();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ManagementSession>();
    final metrics = session.dashboardMetrics;
    final periodTitle = switch (session.dashboardDays) {
      1 => 'HOJE',
      30 => 'ÚLTIMOS 30 DIAS',
      _ => 'ÚLTIMOS 7 DIAS',
    };

    return Column(
      key: const ValueKey('owner-dashboard-v5'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: CDRSpacingTokens.sm),
        Text('VISÃO GERAL',
            style: CDRTypographyTokens.overline
                .copyWith(color: CDRColorTokens.brandYellow)),
        const SizedBox(height: CDRSpacingTokens.sm),
        Text('Seus números, com clareza',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: CDRSpacingTokens.md),
        Wrap(
          spacing: CDRSpacingTokens.sm,
          runSpacing: CDRSpacingTokens.sm,
          children: [
            _DashboardPeriodChip(
              label: 'Hoje',
              days: 1,
              selected: session.dashboardDays == 1,
            ),
            _DashboardPeriodChip(
              label: '7 dias',
              days: 7,
              selected: session.dashboardDays == 7,
            ),
            _DashboardPeriodChip(
              label: '30 dias',
              days: 30,
              selected: session.dashboardDays == 30,
            ),
          ],
        ),
        const SizedBox(height: CDRSpacingTokens.md),
        Text(periodTitle,
            style: CDRTypographyTokens.overline
                .copyWith(color: CDRColorTokens.textSecondary)),
        const SizedBox(height: CDRSpacingTokens.sm),
        if (session.isDashboardLoading && metrics != null)
          const Padding(
            padding: EdgeInsets.only(bottom: CDRSpacingTokens.sm),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: CDRColorTokens.brandYellow,
              backgroundColor: CDRColorTokens.graphiteLight,
            ),
          ),
        if (session.isDashboardLoading && metrics == null)
          const CDRCard(
            child: Padding(
              padding: EdgeInsets.all(CDRSpacingTokens.xxl),
              child: Center(
                child: CircularProgressIndicator(
                  color: CDRColorTokens.brandYellow,
                ),
              ),
            ),
          )
        else if (session.dashboardError != null && metrics == null)
          _DashboardEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Não foi possível carregar os indicadores',
            message: session.dashboardError!,
            action: TextButton.icon(
              onPressed: session.isDashboardLoading
                  ? null
                  : () => session.fetchDashboardMetrics(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          )
        else if (metrics != null) ...[
          _DashboardMetricGrid(metrics: [
            _DashboardMetric('Agendamentos', '${metrics.appointments}',
                Icons.calendar_month_outlined),
            _DashboardMetric('Confirmados', '${metrics.confirmedAppointments}',
                Icons.check_circle_outline),
            _DashboardMetric('Previsto', _money(metrics.projectedRevenue),
                Icons.trending_up_rounded),
            _DashboardMetric('Recebido', _money(metrics.realizedRevenue),
                Icons.payments_outlined),
          ]),
          const SizedBox(height: CDRSpacingTokens.md),
          CDRCard(
            child: Row(children: [
              const _IconBadge(Icons.receipt_long_outlined),
              const SizedBox(width: CDRSpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ticket médio de serviço',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: CDRSpacingTokens.xs),
                    Text(_money(metrics.averageTicket),
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(
                        'Pagamentos de serviços recebidos por atendimento concluído',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: CDRColorTokens.textSecondary)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: CDRSpacingTokens.xxl),
          const _SectionTitle('Evolução no período',
              eyebrow: 'FATURAMENTO E AGENDA'),
          const SizedBox(height: CDRSpacingTokens.md),
          _DashboardTrendCard(
            days: metrics.dailyTrend,
            periodDays: session.dashboardDays,
          ),
        ] else
          const _DashboardEmptyState(
            icon: Icons.insights_outlined,
            title: 'Ainda sem indicadores',
            message: 'Os dados aparecerão aqui assim que houver movimentação.',
          ),
        const SizedBox(height: CDRSpacingTokens.xxl),
      ],
    );
  }

  static String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

class _DashboardPeriodChip extends StatelessWidget {
  const _DashboardPeriodChip({
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
            : (_) => context.read<ManagementSession>().fetchDashboardMetrics(
                  days: days,
                ),
      );
}

class _DashboardTrendCard extends StatelessWidget {
  const _DashboardTrendCard({required this.days, required this.periodDays});
  final List<DashboardDayMetric> days;
  final int periodDays;

  @override
  Widget build(BuildContext context) {
    final metricsTotalRevenue = days.fold<double>(
      0,
      (sum, item) => sum + item.realizedRevenue,
    );
    final metricsTotalAppointments = days.fold<int>(
      0,
      (sum, item) => sum + item.appointments,
    );
    final maxRevenue = days.fold<double>(
      0,
      (max, item) => item.realizedRevenue > max ? item.realizedRevenue : max,
    );
    final hasMovement = days.any(
      (item) => item.appointments > 0 || item.realizedRevenue > 0,
    );
    return CDRCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: CDRSpacingTokens.lg,
            runSpacing: CDRSpacingTokens.sm,
            children: const [
              _DashboardLegend(
                  color: CDRColorTokens.brandYellow, label: 'Recebido'),
              _DashboardLegend(
                  color: CDRColorTokens.textSecondary, label: 'Atendimentos'),
            ],
          ),
          const SizedBox(height: CDRSpacingTokens.lg),
          if (!hasMovement)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: CDRSpacingTokens.xxl),
              child: Center(
                child: Text('Sem movimentação neste período.'),
              ),
            )
          else
            Semantics(
              label: 'Gráfico dos últimos $periodDays dias. '
                  'Recebido: ${_AdminDashboardPage._money(metricsTotalRevenue)}. '
                  'Atendimentos: $metricsTotalAppointments.',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chartWidth = periodDays > 7
                      ? days.length * 20.0
                      : constraints.maxWidth;
                  return Scrollbar(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        height: 190,
                        child: CustomPaint(
                          painter: _DashboardTrendPainter(
                            days: days,
                            maxRevenue: maxRevenue,
                            textColor: CDRColorTokens.textSecondary,
                            revenueColor: CDRColorTokens.brandYellow,
                            appointmentsColor: CDRColorTokens.textSecondary,
                            gridColor: CDRColorTokens.border,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: CDRSpacingTokens.md),
          Text(
            'Recebido considera pagamentos confirmados e vendas concluídas; atendimentos são contados pela data marcada. Cada série usa escala visual própria.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: CDRColorTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DashboardLegend extends StatelessWidget {
  const _DashboardLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: CDRSpacingTokens.xs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _DashboardTrendPainter extends CustomPainter {
  const _DashboardTrendPainter({
    required this.days,
    required this.maxRevenue,
    required this.textColor,
    required this.revenueColor,
    required this.appointmentsColor,
    required this.gridColor,
  });

  final List<DashboardDayMetric> days;
  final double maxRevenue;
  final Color textColor;
  final Color revenueColor;
  final Color appointmentsColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0;
    const top = 8.0;
    const bottom = 30.0;
    final chartHeight = size.height - top - bottom;
    final chartWidth = size.width - left;
    final slot = chartWidth / days.length;
    final maxAppointments = days.fold<int>(
      0,
      (max, item) => item.appointments > max ? item.appointments : max,
    );
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final revenuePaint = Paint()..color = revenueColor;
    final appointmentPaint = Paint()..color = appointmentsColor.withOpacity(.7);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var line = 0; line < 3; line++) {
      final y = top + chartHeight * line / 2;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
    }

    for (var index = 0; index < days.length; index++) {
      final item = days[index];
      final centerX = left + slot * (index + .5);
      final barWidth = (slot * .28).clamp(2.0, 16.0).toDouble();
      final revenueHeight = maxRevenue == 0
          ? 0.0
          : chartHeight * item.realizedRevenue / maxRevenue;
      final appointmentHeight = maxAppointments == 0
          ? 0.0
          : chartHeight * item.appointments / maxAppointments;
      if (revenueHeight > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(centerX - barWidth - 1,
                top + chartHeight - revenueHeight, barWidth, revenueHeight),
            const Radius.circular(4),
          ),
          revenuePaint,
        );
      }
      if (appointmentHeight > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(centerX + 1, top + chartHeight - appointmentHeight,
                barWidth, appointmentHeight),
            const Radius.circular(4),
          ),
          appointmentPaint,
        );
      }
      if (days.length <= 7 ||
          index == 0 ||
          index == days.length - 1 ||
          index % 5 == 0) {
        final label =
            '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}';
        textPainter.text = TextSpan(
          text: label,
          style:
              TextStyle(color: textColor, fontSize: days.length > 7 ? 9 : 10),
        );
        textPainter.layout(maxWidth: slot * 2);
        textPainter.paint(
          canvas,
          Offset(centerX - textPainter.width / 2, size.height - 20),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardTrendPainter oldDelegate) =>
      oldDelegate.days != days || oldDelegate.maxRevenue != maxRevenue;
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
      {required this.icon,
      required this.title,
      required this.message,
      this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

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
          if (action != null) ...[
            const SizedBox(height: CDRSpacingTokens.sm),
            action!,
          ],
        ])),
      ]));
}
