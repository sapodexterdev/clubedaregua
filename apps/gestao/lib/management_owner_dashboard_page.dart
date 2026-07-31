part of 'management.dart';

class _AdminDashboardPage extends StatelessWidget {
  const _AdminDashboardPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(
          cards: [
            _MetricData(
              'Faturamento estimado',
              'R\$ 4.820',
              Icons.trending_up_rounded,
            ),
            _MetricData(
              'Agendamentos na semana',
              '46',
              Icons.event_available_rounded,
            ),
          ],
        ),
        SizedBox(height: 14),
        _InlineNotice(
          icon: Icons.science_outlined,
          title: 'Painel em evolução',
          subtitle:
              'Os indicadores financeiros serão substituídos por dados reais após a integração.',
        ),
        SizedBox(height: 24),
        _SectionTitle(
          'Indicadores operacionais',
          eyebrow: 'VISÃO GERAL',
          trailing: 'Semana atual',
        ),
        SizedBox(height: 12),
        _DashboardInsightsGrid(
          cards: [
            _DashboardInsightData(
              icon: Icons.workspace_premium_outlined,
              label: 'Barbeiro destaque',
              value: 'Equipe ativa',
              detail: '18 atendimentos nesta semana',
            ),
            _DashboardInsightData(
              icon: Icons.content_cut_rounded,
              label: 'Serviço mais vendido',
              value: 'Corte + barba',
              detail: '34% dos agendamentos',
            ),
            _DashboardInsightData(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Caixa do dia',
              value: 'R\$ 1.240',
              detail: 'PIX, dinheiro e cartão',
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardInsightData {
  const _DashboardInsightData({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
}

class _DashboardInsightsGrid extends StatelessWidget {
  const _DashboardInsightsGrid({required this.cards});

  final List<_DashboardInsightData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 540
                ? 2
                : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: _DashboardInsightCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _DashboardInsightCard extends StatelessWidget {
  const _DashboardInsightCard({required this.data});

  final _DashboardInsightData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 164),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(data.icon),
          const SizedBox(height: 14),
          Text(
            data.label.toUpperCase(),
            style: const TextStyle(
              color: SharedAppColors.muted,
              fontSize: 10,
              letterSpacing: .8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(data.value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(data.detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
