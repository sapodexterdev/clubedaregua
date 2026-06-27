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

class ManagementHomeScreen extends StatefulWidget {
  const ManagementHomeScreen({super.key});

  @override
  State<ManagementHomeScreen> createState() => _ManagementHomeScreenState();
}

class _ManagementHomeScreenState extends State<ManagementHomeScreen> {
  var selectedRole = ManagementRole.barber;

  @override
  Widget build(BuildContext context) {
    final isAdmin = selectedRole == ManagementRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Painel administrativo' : 'Agenda do barbeiro'),
        actions: [
          IconButton(
            tooltip: 'Notificações',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _RoleSwitch(
            selectedRole: selectedRole,
            onChanged: (role) => setState(() => selectedRole = role),
          ),
          const SizedBox(height: 18),
          _Header(isAdmin: isAdmin),
          const SizedBox(height: 18),
          if (isAdmin) const _AdminContent() else const _BarberContent(),
        ],
      ),
    );
  }
}

enum ManagementRole { barber, admin }

class _RoleSwitch extends StatelessWidget {
  const _RoleSwitch({
    required this.selectedRole,
    required this.onChanged,
  });

  final ManagementRole selectedRole;
  final ValueChanged<ManagementRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ManagementRole>(
      segments: const [
        ButtonSegment(
          value: ManagementRole.barber,
          label: Text('Barbeiro'),
          icon: Icon(Icons.content_cut_rounded),
        ),
        ButtonSegment(
          value: ManagementRole.admin,
          label: Text('Admin'),
          icon: Icon(Icons.admin_panel_settings_rounded),
        ),
      ],
      selected: {selectedRole},
      onSelectionChanged: (value) => onChanged(value.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SharedAppColors.orange
              : Colors.white,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : SharedAppColors.text,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SharedAppColors.dark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAdmin ? 'Barbearia Elite' : 'Davi Marcomin',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAdmin
                ? 'Controle equipe, serviços, caixa e desempenho da unidade.'
                : 'Confirme atendimentos, bloqueie horários e acompanhe sua comissão.',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _BarberContent extends StatelessWidget {
  const _BarberContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(
          cards: [
            _MetricData('Hoje', '8', Icons.calendar_today_rounded),
            _MetricData('Comissão', 'R\$ 312', Icons.payments_rounded),
          ],
        ),
        SizedBox(height: 22),
        _SectionTitle('Próximos horários'),
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
        _AppointmentTile(
          time: '13:00',
          client: 'Lucas Almeida',
          service: 'Barba completa',
          status: 'Pago',
        ),
        SizedBox(height: 22),
        _SectionTitle('Ações rápidas'),
        SizedBox(height: 12),
        _ShortcutGrid(
          shortcuts: [
            _ShortcutData('Confirmar', Icons.check_circle_rounded),
            _ShortcutData('Bloquear horário', Icons.block_rounded),
            _ShortcutData('Indisponibilidade', Icons.event_busy_rounded),
            _ShortcutData('Clientes', Icons.people_alt_rounded),
          ],
        ),
      ],
    );
  }
}

class _AdminContent extends StatelessWidget {
  const _AdminContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(
          cards: [
            _MetricData('Faturamento', 'R\$ 4.820', Icons.trending_up_rounded),
            _MetricData('Agendamentos', '46', Icons.event_available_rounded),
          ],
        ),
        SizedBox(height: 22),
        _SectionTitle('Indicadores'),
        SizedBox(height: 12),
        _InsightTile(
          title: 'Barbeiro destaque',
          value: 'Davi Marcomin',
          subtitle: '18 atendimentos esta semana',
        ),
        _InsightTile(
          title: 'Serviço mais vendido',
          value: 'Corte + barba',
          subtitle: '34% dos agendamentos',
        ),
        _InsightTile(
          title: 'Caixa do dia',
          value: 'R\$ 1.240',
          subtitle: 'PIX, dinheiro e cartão',
        ),
        SizedBox(height: 22),
        _SectionTitle('Administração'),
        SizedBox(height: 12),
        _ShortcutGrid(
          shortcuts: [
            _ShortcutData('Serviços', Icons.design_services_rounded),
            _ShortcutData('Barbeiros', Icons.badge_rounded),
            _ShortcutData('Cupons', Icons.local_offer_rounded),
            _ShortcutData('Estoque', Icons.inventory_2_rounded),
          ],
        ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.cards});

  final List<_MetricData> cards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          Expanded(child: _MetricCard(data: cards[index])),
          if (index != cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

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
          Icon(data.icon, color: SharedAppColors.orange),
          const SizedBox(height: 16),
          Text(
            data.value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(data.label, style: const TextStyle(color: SharedAppColors.muted)),
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
                Text(client, style: const TextStyle(fontWeight: FontWeight.w900)),
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

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

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
          const Icon(Icons.insights_rounded, color: SharedAppColors.orange),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: SharedAppColors.muted)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: SharedAppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutData {
  const _ShortcutData(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({required this.shortcuts});

  final List<_ShortcutData> shortcuts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: shortcuts.map((item) {
        return SizedBox(
          width: 158,
          height: 48,
          child: FilledButton.tonalIcon(
            onPressed: () {},
            icon: Icon(item.icon),
            label: Text(
              item.label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
    );
  }
}
