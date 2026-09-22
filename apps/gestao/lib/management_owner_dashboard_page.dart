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
            _DashboardMetric(
              title: 'Agendamentos',
              value: '${metrics.appointments}',
              icon: Icons.calendar_month_outlined,
              count: metrics.appointments,
              onTap: () => _openDetails(
                context,
                'appointments',
                session.dashboardDays,
              ),
            ),
            _DashboardMetric(
              title: 'Atendidos',
              value: '${metrics.completedAppointments}',
              icon: Icons.task_alt_outlined,
              count: metrics.completedAppointments,
              onTap: () => _openDetails(
                context,
                'completed',
                session.dashboardDays,
              ),
            ),
            _DashboardMetric(
              title: 'Cancelados',
              value: '${metrics.cancelledAppointments}',
              icon: Icons.event_busy_outlined,
              count: metrics.cancelledAppointments,
              onTap: () => _openDetails(
                context,
                'cancelled',
                session.dashboardDays,
              ),
              helper: 'Pela data marcada',
            ),
            _DashboardMetric(
              title: 'Clientes novos',
              value: '${metrics.newCustomers}',
              icon: Icons.person_add_alt_1_outlined,
              count: metrics.newCustomers,
              onTap: () => _openDetails(
                context,
                'new_customers',
                session.dashboardDays,
              ),
            ),
            _DashboardMetric(
              title: 'Previsto',
              value: _money(metrics.projectedRevenue),
              icon: Icons.trending_up_rounded,
            ),
            _DashboardMetric(
              title: 'Recebido',
              value: _money(metrics.realizedRevenue),
              icon: Icons.payments_outlined,
            ),
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

  void _openDetails(BuildContext context, String kind, int days) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _DashboardDetailsPage(
          session: context.read<ManagementSession>(),
          kind: kind,
          days: days,
        ),
      ),
    );
  }
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

class _DashboardDetailsPage extends StatefulWidget {
  const _DashboardDetailsPage({
    required this.session,
    required this.kind,
    required this.days,
  });

  final ManagementSession session;
  final String kind;
  final int days;

  @override
  State<_DashboardDetailsPage> createState() => _DashboardDetailsPageState();
}

class _DashboardDetailsPageState extends State<_DashboardDetailsPage> {
  late Future<List<DashboardDetailEntry>> _entries;

  String get _title => switch (widget.kind) {
        'appointments' => 'Agendamentos',
        'cancelled' => 'Agendamentos cancelados',
        'completed' => 'Atendimentos realizados',
        _ => 'Clientes novos',
      };

  String get _period => switch (widget.days) {
        1 => 'Hoje',
        30 => 'Últimos 30 dias',
        _ => 'Últimos 7 dias',
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _entries = widget.session.fetchDashboardDetails(
      kind: widget.kind,
      days: widget.days,
    );
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CDRColorTokens.night,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: CDRColorTokens.night,
      ),
      body: FutureBuilder<List<DashboardDetailEntry>>(
        future: _entries,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: CDRColorTokens.brandYellow,
              ),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(CDRSpacingTokens.lg),
              child: _DashboardEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Não foi possível carregar os detalhes',
                message: snapshot.error
                    .toString()
                    .replaceFirst(RegExp(r'^Bad state:\s*'), '')
                    .replaceFirst(RegExp(r'^Exception:\s*'), ''),
                action: TextButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ),
            );
          }

          final entries = snapshot.data ?? const <DashboardDetailEntry>[];
          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(CDRSpacingTokens.lg),
              child: _DashboardEmptyState(
                icon: Icons.event_busy_outlined,
                title: 'Nenhum registro neste período',
                message: 'Não encontramos $_title em ${_period.toLowerCase()}.',
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CDRSizeTokens.managementContentMaxWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.all(CDRSpacingTokens.lg),
                children: [
                  Text(
                    _period.toUpperCase(),
                    style: CDRTypographyTokens.overline
                        .copyWith(color: CDRColorTokens.brandYellow),
                  ),
                  const SizedBox(height: CDRSpacingTokens.sm),
                  Text(
                    '${entries.length} ${entries.length == 1 ? 'registro' : 'registros'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CDRColorTokens.textSecondary,
                        ),
                  ),
                  if (entries.length == 500) ...[
                    const SizedBox(height: CDRSpacingTokens.xs),
                    Text(
                      'Exibindo os 500 registros mais recentes. O card mantém o total do período.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: CDRColorTokens.textSecondary,
                          ),
                    ),
                  ],
                  if (widget.kind == 'cancelled') ...[
                    const SizedBox(height: CDRSpacingTokens.xs),
                    Text(
                      'Considera a data marcada do agendamento.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: CDRColorTokens.textSecondary,
                          ),
                    ),
                  ],
                  const SizedBox(height: CDRSpacingTokens.md),
                  for (final entry in entries) ...[
                    _DashboardDetailCard(entry: entry, kind: widget.kind),
                    const SizedBox(height: CDRSpacingTokens.sm),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardDetailCard extends StatelessWidget {
  const _DashboardDetailCard({required this.entry, required this.kind});

  final DashboardDetailEntry entry;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final date = entry.occurredAt.toLocal();
    final dateLabel = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeLabel = '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    final isCustomer = kind == 'new_customers';
    final status = switch (entry.status) {
      'pending' => 'Pendente',
      'confirmed' => 'Confirmado',
      'completed' => 'Atendido',
      'cancelled' => 'Cancelado',
      _ => null,
    };

    return CDRCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                isCustomer
                    ? Icons.person_outline
                    : Icons.calendar_month_outlined,
              ),
              const SizedBox(width: CDRSpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.customerName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (isCustomer)
                      Text(
                        'Cliente desde $dateLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: CDRColorTokens.textSecondary,
                            ),
                      )
                    else ...[
                      Text(
                        '${entry.serviceName ?? 'Serviço'} · $dateLabel às $timeLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: CDRColorTokens.textSecondary,
                            ),
                      ),
                      if ((entry.barberName ?? '').isNotEmpty)
                        Text(
                          entry.barberName!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: CDRColorTokens.textSecondary,
                                  ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (status != null ||
              (entry.cancellationReason?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: CDRSpacingTokens.md),
            Wrap(
              spacing: CDRSpacingTokens.sm,
              runSpacing: CDRSpacingTokens.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CDRSpacingTokens.sm,
                      vertical: CDRSpacingTokens.xs,
                    ),
                    decoration: BoxDecoration(
                      color: kind == 'cancelled'
                          ? CDRColorTokens.error.withOpacity(.12)
                          : CDRColorTokens.success.withOpacity(.12),
                      borderRadius: BorderRadius.circular(CDRRadiusTokens.pill),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: kind == 'cancelled'
                                ? CDRColorTokens.error
                                : CDRColorTokens.success,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                if (entry.cancellationReason?.trim().isNotEmpty ?? false)
                  Text(
                    'Motivo: ${entry.cancellationReason}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CDRColorTokens.textSecondary,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
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
                  color: CDRColorTokens.textSecondary, label: 'Agendamentos'),
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
                  'Agendamentos: $metricsTotalAppointments.',
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
            'Recebido considera pagamentos confirmados e vendas concluídas; agendamentos não cancelados são contados pela data marcada. Cada série usa escala visual própria.',
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
  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.icon,
    this.count,
    this.onTap,
    this.helper,
  });

  final String title;
  final String value;
  final IconData icon;
  final int? count;
  final VoidCallback? onTap;
  final String? helper;
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
                        key: ValueKey('owner-dashboard-card-${metric.title}'),
                        onTap: metric.count != null && metric.count! > 0
                            ? metric.onTap
                            : null,
                        semanticLabel: metric.count == null
                            ? '${metric.title}: ${metric.value}. Indicador informativo.'
                            : metric.count! > 0
                                ? '${metric.title}: ${metric.value}. Abrir detalhes.'
                                : '${metric.title}: ${metric.value}. Sem registros para abrir.',
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
                                            color:
                                                CDRColorTokens.textSecondary)),
                                const SizedBox(height: CDRSpacingTokens.xs),
                                Text(metric.value,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                if (metric.helper != null) ...[
                                  const SizedBox(height: CDRSpacingTokens.xs),
                                  Text(
                                    metric.helper!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: CDRColorTokens.textSecondary,
                                        ),
                                  ),
                                ],
                              ])),
                          if (metric.count != null && metric.count! > 0) ...[
                            const SizedBox(width: CDRSpacingTokens.sm),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: CDRColorTokens.textSecondary,
                            ),
                          ],
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
