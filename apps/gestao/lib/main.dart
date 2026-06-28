import 'dart:convert';

import 'package:clubedaregua_shared/clubedaregua_shared.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ManagementSession(),
      child: const ClubeDaReguaGestaoApp(),
    ),
  );
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
      home: Consumer<ManagementSession>(
        builder: (context, session, _) {
          if (!session.isSignedIn) return const ManagementLoginScreen();
          return const ManagementHomeScreen();
        },
      ),
    );
  }
}

class GestaoSupabaseConfig {
  const GestaoSupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      url.startsWith('https://') && anonKey.trim().isNotEmpty;
}

class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.client,
    required this.phone,
    required this.service,
    required this.barber,
    required this.date,
    required this.time,
    required this.status,
    required this.total,
  });

  final String id;
  final String client;
  final String phone;
  final String service;
  final String barber;
  final String date;
  final String time;
  final String status;
  final double total;

  factory BookingRequest.fromMap(Map<String, dynamic> map) {
    return BookingRequest(
      id: map['id']?.toString() ?? '',
      client: map['customer_name']?.toString() ?? 'Cliente',
      phone: map['customer_phone']?.toString() ?? '',
      service: map['services']?['name']?.toString() ?? 'Servico',
      barber: map['barbers']?['name']?.toString() ?? 'Barbeiro',
      date: map['requested_date']?.toString() ?? '',
      time: _timeOnly(map['requested_time']?.toString() ?? ''),
      status: map['status']?.toString() ?? 'new',
      total: (map['total_price'] as num?)?.toDouble() ?? 0,
    );
  }

  static String _timeOnly(String value) {
    if (value.length >= 5) return value.substring(0, 5);
    return value;
  }
}

class ManagementSession extends ChangeNotifier {
  String? _accessToken;
  String? email;
  bool isLoading = false;
  String? errorMessage;
  List<BookingRequest> bookingRequests = [];

  bool get isSignedIn => _accessToken != null;

  Future<void> signIn(String emailValue, String password) async {
    if (!GestaoSupabaseConfig.isConfigured) {
      errorMessage = 'Configure SUPABASE_URL e SUPABASE_ANON_KEY.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${GestaoSupabaseConfig.url}/auth/v1/token',
      ).replace(queryParameters: {'grant_type': 'password'});

      final response = await http.post(
        uri,
        headers: {
          'apikey': GestaoSupabaseConfig.anonKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'email': emailValue.trim(),
          'password': password,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Login invalido ou usuario sem acesso.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['access_token']?.toString();
      email = emailValue.trim();
      await fetchBookingRequests();
    } catch (error) {
      _accessToken = null;
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookingRequests() async {
    final token = _accessToken;
    if (token == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${GestaoSupabaseConfig.url}/rest/v1/booking_requests',
      ).replace(queryParameters: {
        'select':
            'id,customer_name,customer_phone,requested_date,requested_time,status,total_price,barbers(name),services(name)',
        'order': 'created_at.desc',
        'limit': '20',
      });

      final response = await http.get(
        uri,
        headers: {
          'apikey': GestaoSupabaseConfig.anonKey,
          'authorization': 'Bearer $token',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Nao foi possivel carregar pedidos.');
      }

      final rows = jsonDecode(response.body) as List<dynamic>;
      bookingRequests = rows
          .whereType<Map>()
          .map((row) => BookingRequest.fromMap(Map<String, dynamic>.from(row)))
          .toList();
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void signOut() {
    _accessToken = null;
    email = null;
    bookingRequests = [];
    errorMessage = null;
    notifyListeners();
  }
}

class ManagementLoginScreen extends StatefulWidget {
  const ManagementLoginScreen({super.key});

  @override
  State<ManagementLoginScreen> createState() => _ManagementLoginScreenState();
}

class _ManagementLoginScreenState extends State<ManagementLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ManagementSession>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.content_cut_rounded,
                    color: SharedAppColors.orange,
                    size: 58,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Clube da Regua Gestao',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entre para ver pedidos, agenda e operacao da barbearia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: SharedAppColors.muted),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: session.isLoading
                        ? null
                        : () => session.signIn(
                              _emailController.text,
                              _passwordController.text,
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: SharedAppColors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: Text(session.isLoading ? 'Entrando...' : 'Entrar'),
                  ),
                  if (session.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      session.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ManagementRole { barber, admin }

class ManagementHomeScreen extends StatefulWidget {
  const ManagementHomeScreen({super.key});

  @override
  State<ManagementHomeScreen> createState() => _ManagementHomeScreenState();
}

class _ManagementHomeScreenState extends State<ManagementHomeScreen> {
  var selectedRole = ManagementRole.barber;
  var selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = selectedRole == ManagementRole.admin;
    final tabs = isAdmin ? _adminTabs : _barberTabs;
    final safeTab = selectedTab >= tabs.length ? 0 : selectedTab;
    final page = tabs[safeTab];

    return Scaffold(
      appBar: AppBar(
        title: Text(page.title),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => context.read<ManagementSession>().fetchBookingRequests(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Notificações',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () => context.read<ManagementSession>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeTab,
        backgroundColor: Colors.white,
        indicatorColor: SharedAppColors.orange.withOpacity(.14),
        onDestinationSelected: (index) => setState(() => selectedTab = index),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _RoleSwitch(
            selectedRole: selectedRole,
            onChanged: (role) {
              setState(() {
                selectedRole = role;
                selectedTab = 0;
              });
            },
          ),
          const SizedBox(height: 18),
          _Header(isAdmin: isAdmin),
          const SizedBox(height: 18),
          page.child,
        ],
      ),
    );
  }
}

class _ManagementTab {
  const _ManagementTab({
    required this.label,
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.child,
  });

  final String label;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget child;
}

const _barberTabs = [
  _ManagementTab(
    label: 'Pedidos',
    title: 'Solicitacoes recebidas',
    icon: Icons.inbox_outlined,
    selectedIcon: Icons.inbox_rounded,
    child: _BookingRequestsPage(),
  ),
  _ManagementTab(
    label: 'Agenda',
    title: 'Agenda do barbeiro',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    child: _BarberAgendaPage(),
  ),
  _ManagementTab(
    label: 'Horários',
    title: 'Disponibilidade',
    icon: Icons.schedule_outlined,
    selectedIcon: Icons.schedule_rounded,
    child: _AvailabilityPage(),
  ),
  _ManagementTab(
    label: 'Clientes',
    title: 'Clientes atendidos',
    icon: Icons.people_alt_outlined,
    selectedIcon: Icons.people_alt_rounded,
    child: _ClientsPage(),
  ),
  _ManagementTab(
    label: 'Comissão',
    title: 'Comissão e faturamento',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments_rounded,
    child: _CommissionPage(),
  ),
];

const _adminTabs = [
  _ManagementTab(
    label: 'Pedidos',
    title: 'Solicitacoes recebidas',
    icon: Icons.inbox_outlined,
    selectedIcon: Icons.inbox_rounded,
    child: _BookingRequestsPage(),
  ),
  _ManagementTab(
    label: 'Painel',
    title: 'Painel administrativo',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    child: _AdminDashboardPage(),
  ),
  _ManagementTab(
    label: 'Serviços',
    title: 'Cadastro de serviços',
    icon: Icons.design_services_outlined,
    selectedIcon: Icons.design_services_rounded,
    child: _ServicesPage(),
  ),
  _ManagementTab(
    label: 'Equipe',
    title: 'Cadastro de barbeiros',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge_rounded,
    child: _TeamPage(),
  ),
  _ManagementTab(
    label: 'Caixa',
    title: 'Caixa e estoque',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale_rounded,
    child: _CashPage(),
  ),
];

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

class _BarberAgendaPage extends StatelessWidget {
  const _BarberAgendaPage();

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
      ],
    );
  }
}

class _BookingRequestsPage extends StatelessWidget {
  const _BookingRequestsPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagementSession>(
      builder: (context, session, _) {
        final requests = session.bookingRequests;
        final newCount =
            requests.where((request) => request.status == 'new').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricsGrid(
              cards: [
                _MetricData(
                  'Novas',
                  '$newCount',
                  Icons.mark_email_unread_rounded,
                ),
                _MetricData('Pedidos', '${requests.length}', Icons.today_rounded),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Novas solicitacoes'),
            const SizedBox(height: 12),
            if (session.isLoading) ...[
              const LinearProgressIndicator(color: SharedAppColors.orange),
              const SizedBox(height: 12),
            ],
            if (session.errorMessage != null)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                title: 'Nao foi possivel carregar',
                subtitle: session.errorMessage!,
              )
            else if (requests.isEmpty)
              const _InlineNotice(
                icon: Icons.inbox_rounded,
                title: 'Nenhum pedido por enquanto',
                subtitle: 'As solicitacoes do app cliente aparecerao aqui.',
              )
            else
              for (final request in requests)
                _BookingRequestTile(
                  client: request.client,
                  phone: request.phone,
                  service: request.service,
                  dateTime: '${request.date} - ${request.time}',
                  total: _formatCurrency(request.total),
                ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    return 'R\$ ${parts[0]},${parts[1]}';
  }
}

class _AvailabilityPage extends StatelessWidget {
  const _AvailabilityPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Horários disponíveis'),
        SizedBox(height: 12),
        _ScheduleTile(day: 'Segunda a sexta', hours: '09:00 - 18:00'),
        _ScheduleTile(day: 'Sábado', hours: '09:00 - 14:00'),
        SizedBox(height: 22),
        _SectionTitle('Bloqueios'),
        SizedBox(height: 12),
        _BlockedTile(
          title: 'Almoço estendido',
          detail: 'Hoje, 12:00 - 13:30',
        ),
        _BlockedTile(
          title: 'Férias programadas',
          detail: '12/08 até 18/08',
        ),
        SizedBox(height: 22),
        _ActionPanel(
          title: 'Ajustar disponibilidade',
          subtitle: 'Crie horários fixos, folgas ou bloqueios rápidos.',
          buttonLabel: 'Novo bloqueio',
          icon: Icons.event_busy_rounded,
        ),
      ],
    );
  }
}

class _ClientsPage extends StatelessWidget {
  const _ClientsPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchBox(hint: 'Buscar cliente'),
        SizedBox(height: 18),
        _ClientTile(
          name: 'Marcos Lima',
          detail: '12 visitas - último corte hoje',
          points: '920 pts',
        ),
        _ClientTile(
          name: 'João Pedro',
          detail: '5 visitas - prefere corte baixo',
          points: '410 pts',
        ),
        _ClientTile(
          name: 'Lucas Almeida',
          detail: '8 visitas - barba quinzenal',
          points: '680 pts',
        ),
      ],
    );
  }
}

class _CommissionPage extends StatelessWidget {
  const _CommissionPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsGrid(
          cards: [
            _MetricData('Semana', 'R\$ 1.780', Icons.trending_up_rounded),
            _MetricData('Comissão', 'R\$ 712', Icons.account_balance_wallet_rounded),
          ],
        ),
        SizedBox(height: 22),
        _SectionTitle('Resumo'),
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
      ],
    );
  }
}

class _AdminDashboardPage extends StatelessWidget {
  const _AdminDashboardPage();

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
      ],
    );
  }
}

class _ServicesPage extends StatelessWidget {
  const _ServicesPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActionPanel(
          title: 'Catálogo de serviços',
          subtitle: 'Cadastre preços, duração e comissão por serviço.',
          buttonLabel: 'Novo serviço',
          icon: Icons.add_circle_rounded,
        ),
        SizedBox(height: 18),
        _ServiceTile(name: 'Corte premium', price: 'R\$ 55', duration: '45 min'),
        _ServiceTile(name: 'Barba completa', price: 'R\$ 40', duration: '35 min'),
        _ServiceTile(name: 'Corte + barba', price: 'R\$ 85', duration: '70 min'),
      ],
    );
  }
}

class _TeamPage extends StatelessWidget {
  const _TeamPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActionPanel(
          title: 'Equipe da unidade',
          subtitle: 'Gerencie barbeiros, permissões e percentuais.',
          buttonLabel: 'Novo barbeiro',
          icon: Icons.person_add_alt_1_rounded,
        ),
        SizedBox(height: 18),
        _TeamTile(
          name: 'Davi Marcomin',
          role: 'Barbeiro principal',
          detail: '40% comissão - agenda ativa',
        ),
        _TeamTile(
          name: 'Ricardo Anderson',
          role: 'Barbeiro',
          detail: '35% comissão - agenda ativa',
        ),
        _TeamTile(
          name: 'Camila Rocha',
          role: 'Recepção',
          detail: 'Acesso a agenda e caixa',
        ),
      ],
    );
  }
}

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
        SizedBox(height: 22),
        _SectionTitle('Movimentos de caixa'),
        SizedBox(height: 12),
        _CashMovementTile(title: 'PIX - Marcos Lima', value: '+ R\$ 85'),
        _CashMovementTile(title: 'Dinheiro - João Pedro', value: '+ R\$ 55'),
        _CashMovementTile(title: 'Compra de pomada', value: '- R\$ 180'),
        SizedBox(height: 22),
        _SectionTitle('Estoque crítico'),
        SizedBox(height: 12),
        _StockTile(name: 'Pomada modeladora', quantity: '3 un'),
        _StockTile(name: 'Lâmina descartável', quantity: '18 un'),
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

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _IconBadge(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: SharedAppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return _SurfaceTile(
      leading: _TimeBadge(time),
      title: client,
      subtitle: service,
      trailing: Chip(
        label: Text(status),
        side: BorderSide.none,
        backgroundColor: SharedAppColors.background,
      ),
    );
  }
}

class _BookingRequestTile extends StatelessWidget {
  const _BookingRequestTile({
    required this.client,
    required this.phone,
    required this.service,
    required this.dateTime,
    required this.total,
  });

  final String client;
  final String phone;
  final String service;
  final String dateTime;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(Icons.event_available_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$service - $dateTime',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: SharedAppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                total,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text(phone),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: SharedAppColors.orange,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Confirmar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge(this.time);

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.day, required this.hours});

  final String day;
  final String hours;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.schedule_rounded),
      title: day,
      subtitle: hours,
      trailing: const Icon(Icons.edit_rounded, color: SharedAppColors.muted),
    );
  }
}

class _BlockedTile extends StatelessWidget {
  const _BlockedTile({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.block_rounded),
      title: title,
      subtitle: detail,
      trailing: const Icon(Icons.more_horiz_rounded, color: SharedAppColors.muted),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({
    required this.name,
    required this.detail,
    required this.points,
  });

  final String name;
  final String detail;
  final String points;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const CircleAvatar(
        radius: 25,
        backgroundColor: SharedAppColors.orange,
        child: Icon(Icons.person_rounded, color: Colors.white),
      ),
      title: name,
      subtitle: detail,
      trailing: Text(
        points,
        style: const TextStyle(
          color: SharedAppColors.orange,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.name,
    required this.price,
    required this.duration,
  });

  final String name;
  final String price;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.content_cut_rounded),
      title: name,
      subtitle: duration,
      trailing: Text(
        price,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.name,
    required this.role,
    required this.detail,
  });

  final String name;
  final String role;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const CircleAvatar(
        radius: 25,
        backgroundColor: SharedAppColors.dark,
        child: Icon(Icons.person_rounded, color: Colors.white),
      ),
      title: name,
      subtitle: '$role • $detail',
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _CashMovementTile extends StatelessWidget {
  const _CashMovementTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isPositive = value.trim().startsWith('+');
    return _SurfaceTile(
      leading: _IconBadge(
        isPositive ? Icons.south_west_rounded : Icons.north_east_rounded,
      ),
      title: title,
      subtitle: isPositive ? 'Entrada' : 'Saída',
      trailing: Text(
        value,
        style: TextStyle(
          color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.name, required this.quantity});

  final String name;
  final String quantity;

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      leading: const _IconBadge(Icons.inventory_2_rounded),
      title: name,
      subtitle: 'Reposição recomendada',
      trailing: Text(
        quantity,
        style: const TextStyle(fontWeight: FontWeight.w900),
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
    return _SurfaceTile(
      leading: const _IconBadge(Icons.insights_rounded),
      title: value,
      subtitle: '$title • $subtitle',
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _IconBadge(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: SharedAppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: SharedAppColors.orange,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _SurfaceTile extends StatelessWidget {
  const _SurfaceTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;

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
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SharedAppColors.muted),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SharedAppColors.orange.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: SharedAppColors.orange),
    );
  }
}
