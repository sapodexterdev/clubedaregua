import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/metric_card.dart';
import 'barber_form_screen.dart';
import 'service_form_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const route = '/admin-dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel do Administrador')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Operação Clube da Régua',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Faturamento',
                  value: 'R\$ 8.920',
                  icon: Icons.trending_up_rounded,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  title: 'Caixa',
                  value: 'R\$ 1.430',
                  icon: Icons.point_of_sale_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Ranking #1',
                  value: 'Lucas',
                  icon: Icons.emoji_events_rounded,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  title: 'Mais vendido',
                  value: 'Combo',
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AdminTile(
            title: 'Cadastrar barbeiros',
            icon: Icons.person_add_alt_1_rounded,
            onTap: () => Navigator.pushNamed(context, BarberFormScreen.route),
          ),
          _AdminTile(
            title: 'Cadastrar serviços',
            icon: Icons.add_business_rounded,
            onTap: () => Navigator.pushNamed(context, ServiceFormScreen.route),
          ),
          _AdminTile(
            title: 'Controle de agenda',
            icon: Icons.calendar_month_rounded,
            onTap: () {},
          ),
          _AdminTile(
            title: 'Cupons promocionais',
            icon: Icons.local_offer_rounded,
            onTap: () {},
          ),
          _AdminTile(
            title: 'Estoque básico',
            icon: Icons.inventory_2_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
