part of 'main.dart';

class _CommissionPage extends StatelessWidget {
  const _CommissionPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(
          cards: [
            _MetricData(
              'Produção na semana',
              'R\$ 1.780',
              Icons.trending_up_rounded,
            ),
            _MetricData(
              'Comissão estimada',
              'R\$ 712',
              Icons.account_balance_wallet_rounded,
            ),
          ],
        ),
        SizedBox(height: 14),
        _InlineNotice(
          icon: Icons.science_outlined,
          title: 'Prévia financeira',
          subtitle:
              'Valores ilustrativos enquanto a movimentação financeira real não está ativa.',
        ),
        SizedBox(height: 24),
        _SectionTitle(
          'Desempenho da semana',
          eyebrow: 'COMISSÃO',
          trailing: 'Período atual',
        ),
        SizedBox(height: 12),
        _InsightTile(
          title: 'Atendimentos concluídos',
          value: '31',
          subtitle: 'Ticket médio de R\$ 57',
        ),
        _InsightTile(
          title: 'Serviço mais feito',
          value: 'Corte + barba',
          subtitle: '14 atendimentos no período',
        ),
        SizedBox(height: 28),
        _SectionTitle(
          'Resumo financeiro',
          eyebrow: 'FATURAMENTO',
          trailing: 'Estimativa',
        ),
        SizedBox(height: 12),
        _CommissionBreakdown(),
      ],
    );
  }
}

class _CommissionBreakdown extends StatelessWidget {
  const _CommissionBreakdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SharedAppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SharedAppColors.stroke),
      ),
      child: const Column(
        children: [
          _FinancialLine(label: 'Produção bruta', value: 'R\$ 1.780,00'),
          Divider(height: 28),
          _FinancialLine(
            label: 'Comissão estimada (40%)',
            value: 'R\$ 712,00',
            emphasized: true,
          ),
          Divider(height: 28),
          _FinancialLine(
            label: 'Repasse da barbearia',
            value: 'R\$ 1.068,00',
          ),
        ],
      ),
    );
  }
}

class _FinancialLine extends StatelessWidget {
  const _FinancialLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? SharedAppColors.text : SharedAppColors.muted,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: TextStyle(
            color: emphasized ? SharedAppColors.orange : SharedAppColors.text,
            fontSize: emphasized ? 18 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
