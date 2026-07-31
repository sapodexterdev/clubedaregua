part of 'main.dart';

class _CashPage extends StatelessWidget {
  const _CashPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(
          cards: [
            _MetricData('Entradas', 'R\$ 1.240', Icons.south_west_rounded),
            _MetricData('Saídas', 'R\$ 180', Icons.north_east_rounded),
          ],
        ),
        SizedBox(height: 14),
        _InlineNotice(
          icon: Icons.science_outlined,
          title: 'Prévia do caixa',
          subtitle:
              'Movimentos ilustrativos enquanto a integração financeira não está ativa.',
        ),
        SizedBox(height: 24),
        _SectionTitle(
          'Movimentos de caixa',
          eyebrow: 'FINANCEIRO',
          trailing: 'Hoje',
        ),
        SizedBox(height: 12),
        _CashMovementTile(title: 'PIX - Marcos Lima', value: '+ R\$ 85'),
        _CashMovementTile(title: 'Dinheiro - João Pedro', value: '+ R\$ 55'),
        _CashMovementTile(title: 'Compra de pomada', value: '- R\$ 180'),
        SizedBox(height: 24),
        _SectionTitle(
          'Estoque crítico',
          eyebrow: 'PRODUTOS',
          trailing: '2 alertas',
        ),
        SizedBox(height: 12),
        _StockTile(name: 'Pomada modeladora', quantity: '3 un'),
        _StockTile(name: 'Lâmina descartável', quantity: '18 un'),
      ],
    );
  }
}
