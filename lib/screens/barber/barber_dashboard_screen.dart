import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/primary_button.dart';
import 'barber_agenda_screen.dart';

class BarberDashboardScreen extends StatelessWidget {
  const BarberDashboardScreen({super.key});

  static const route = '/barber-dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Barbeiro')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Agenda do dia',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Atendimentos',
                  value: '8',
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  title: 'Comissao',
                  value: 'R\$ 312',
                  icon: Icons.payments_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ActionTile(
            title: 'Confirmar atendimento',
            subtitle: 'Marque servicos concluidos e gere pontos.',
            icon: Icons.check_circle_rounded,
            onTap: () {},
          ),
          _ActionTile(
            title: 'Bloquear horarios',
            subtitle: 'Reserve pausas, encaixes e compromissos.',
            icon: Icons.block_rounded,
            onTap: () => Navigator.pushNamed(context, BarberAgendaScreen.route),
          ),
          _ActionTile(
            title: 'Ferias e indisponibilidade',
            subtitle: 'Cadastre periodos sem atendimento.',
            icon: Icons.beach_access_rounded,
            onTap: () {},
          ),
          _ActionTile(
            title: 'Clientes',
            subtitle: 'Veja historico e proximos retornos.',
            icon: Icons.people_alt_rounded,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Abrir agenda completa',
            onPressed: () => Navigator.pushNamed(context, BarberAgendaScreen.route),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
