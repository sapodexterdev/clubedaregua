import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ClubeDaReguaGestaoApp());
}

class ClubeDaReguaGestaoApp extends StatelessWidget {
  const ClubeDaReguaGestaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clube da Régua Gestão',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: SharedAppColors.orange,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: SharedAppColors.background,
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const ManagementHomeScreen(),
    );
  }
}

class ManagementHomeScreen extends StatelessWidget {
  const ManagementHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Gestão'),
        actions: [
          IconButton(
            tooltip: 'Notificações',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Header(),
          SizedBox(height: 18),
          _MetricsGrid(),
          SizedBox(height: 22),
          _SectionTitle('Agenda de hoje'),
          SizedBox(height: 12),
          _AppointmentTile(
            time: '09:00',
            client: 'Marcos Lima',
            service: 'Corte + barba',
            status: 'Confirmado',
          ),
          _AppointmentTile(
            time: '10:30',
            client: 'João Pedro',
            service: 'Corte premium',
            status: 'Pendente',
          ),
          SizedBox(height: 22),
          _SectionTitle('Atalhos'),
          SizedBox(height: 12),
          _ShortcutGrid(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SharedAppColors.dark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Barbearia Pro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Gerencie agenda, equipe e faturamento em um só lugar.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Hoje',
            value: '12',
            icon: Icons.calendar_today_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: 'Faturamento',
            value: 'R\$ 840',
            icon: Icons.trending_up_rounded,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SharedAppColors.orange),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: SharedAppColors.muted)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({
    required this.time,
    required this.client,
    required this.service,
    required this.status,
  });

  final String time;
  final String client;
  final String service;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SharedAppColors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              time,
              style: const TextStyle(
                color: SharedAppColors.orange,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(service, style: const TextStyle(color: SharedAppColors.muted)),
              ],
            ),
          ),
          Chip(
            label: Text(status),
            side: BorderSide.none,
            backgroundColor: SharedAppColors.background,
          ),
        ],
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid();

  @override
  Widget build(BuildContext context) {
    const shortcuts = [
      ('Agenda', Icons.calendar_month_rounded),
      ('Serviços', Icons.design_services_rounded),
      ('Barbeiros', Icons.people_alt_rounded),
      ('Caixa', Icons.point_of_sale_rounded),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: shortcuts.map((item) {
        return SizedBox(
          width: 150,
          child: FilledButton.tonalIcon(
            onPressed: () {},
            icon: Icon(item.$2),
            label: Text(item.$1),
          ),
        );
      }).toList(),
    );
  }
}
