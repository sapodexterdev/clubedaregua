part of 'management.dart';

enum ManagementRole { barber, admin }

class ManagementHomeScreen extends StatefulWidget {
  const ManagementHomeScreen({
    this.initialRole,
    this.onOpenClientMode = _ignoreClientModeNavigation,
    this.onOpenProfile,
    this.onRoleChanged,
    this.onSignedOut,
    super.key,
  });

  final ManagementRole? initialRole;
  final VoidCallback onOpenClientMode;
  final VoidCallback? onOpenProfile;
  final Future<void> Function(ManagementRole role)? onRoleChanged;
  final VoidCallback? onSignedOut;

  @override
  State<ManagementHomeScreen> createState() => _ManagementHomeScreenState();
}

class _ManagementHomeScreenState extends State<ManagementHomeScreen> {
  late ManagementRole selectedRole;
  var selectedTab = 0;

  @override
  void initState() {
    super.initState();
    selectedRole = widget.initialRole ??
        (Uri.base.queryParameters['mode'] == 'owner'
            ? ManagementRole.admin
            : ManagementRole.barber);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ManagementSession>();
    final effectiveRole = switch (selectedRole) {
      ManagementRole.admin when session.canManageShop => ManagementRole.admin,
      ManagementRole.barber when session.canWorkAsBarber =>
        ManagementRole.barber,
      _ when session.canManageShop => ManagementRole.admin,
      _ => ManagementRole.barber,
    };
    final isAdmin = effectiveRole == ManagementRole.admin;
    final tabs = isAdmin ? _adminTabs : _barberTabs;
    final safeTab = selectedTab >= tabs.length ? 0 : selectedTab;
    final page = tabs[safeTab];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideNavigation = constraints.maxWidth >= 900;
        final extendedNavigation = constraints.maxWidth >= 1280;
        return Scaffold(
          backgroundColor: SharedAppColors.background,
          appBar: _ManagementTopBar(
            title: page.title,
            onOpenClientMode: widget.onOpenClientMode,
            onOpenProfile: widget.onOpenProfile,
            onRefresh: _refreshCurrentTab,
            onSignedOut: widget.onSignedOut,
          ),
          bottomNavigationBar: useSideNavigation
              ? null
              : _ManagementBottomNavigation(
                  tabs: tabs,
                  selectedIndex: safeTab,
                  onSelected: _selectTab,
                ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (useSideNavigation)
                _ManagementSideNavigation(
                  tabs: tabs,
                  selectedIndex: safeTab,
                  extended: extendedNavigation,
                  onSelected: _selectTab,
                ),
              Expanded(
                child: _ManagementPageContent(
                  horizontalPadding: useSideNavigation ? 32 : 16,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: session.canWorkAsBarber && session.canManageShop
                          ? _RoleSwitch(
                              selectedRole: effectiveRole,
                              onChanged: _changeRole,
                            )
                          : _AvailabilityStatus(
                              label: isAdmin ? 'MODO DONO' : 'MODO BARBEIRO',
                              color: SharedAppColors.orange,
                            ),
                    ),
                    const SizedBox(height: 16),
                    _Header(
                      isAdmin: isAdmin,
                      title: isAdmin
                          ? session.barberShopName ?? 'Barbearia'
                          : session.barberHeaderName,
                    ),
                    const SizedBox(height: 24),
                    page.child,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectTab(int index) {
    setState(() => selectedTab = index);
    unawaited(
      context.read<ManagementSession>().ensureDataForTab(
            selectedRole,
            index,
          ),
    );
  }

  Future<void> _refreshCurrentTab() =>
      context.read<ManagementSession>().ensureDataForTab(
            selectedRole,
            selectedTab,
            force: true,
          );

  Future<void> _changeRole(ManagementRole role) async {
    if (role == selectedRole) return;

    setState(() {
      selectedRole = role;
      selectedTab = 0;
    });

    await context.read<ManagementSession>().activateRole(role);
    if (!mounted) return;

    final onRoleChanged = widget.onRoleChanged;
    if (onRoleChanged != null) {
      await onRoleChanged(role);
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'clubedaregua.last_mode',
      role == ManagementRole.admin ? 'owner' : 'barber',
    );
  }
}

class _ManagementTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _ManagementTopBar({
    required this.title,
    required this.onOpenClientMode,
    required this.onRefresh,
    this.onOpenProfile,
    this.onSignedOut,
  });

  final String title;
  final VoidCallback onOpenClientMode;
  final VoidCallback onRefresh;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onSignedOut;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return AppBar(
      toolbarHeight: 68,
      titleSpacing: compact ? 16 : 22,
      backgroundColor: SharedAppColors.background,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: SharedAppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SharedAppColors.stroke),
            ),
            child: SvgPicture.asset(
              'assets/images/brand_v3_segunda_logo.svg',
              fit: BoxFit.contain,
              semanticsLabel: 'Clube da Régua',
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CLUBE DA RÉGUA • GESTÃO',
                  style: TextStyle(
                    color: SharedAppColors.orange,
                    fontSize: 9,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _TopBarAction(
          tooltip: 'Notificações',
          onPressed: () {},
          icon: Icons.notifications_none_rounded,
        ),
        if (compact)
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'client':
                  onOpenClientMode();
                  return;
                case 'profile':
                  onOpenProfile?.call();
                  return;
                case 'refresh':
                  onRefresh();
                  return;
                case 'logout':
                  (onSignedOut ?? context.read<ManagementSession>().signOut)();
                  return;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'client',
                child: Text('Modo cliente'),
              ),
              if (onOpenProfile != null)
                const PopupMenuItem(
                  value: 'profile',
                  child: Text('Perfil e modos'),
                ),
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Atualizar dados'),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Sair')),
            ],
          )
        else ...[
          _TopBarAction(
            tooltip: 'Modo cliente',
            onPressed: onOpenClientMode,
            icon: Icons.swap_horiz_rounded,
          ),
          if (onOpenProfile != null)
            _TopBarAction(
              tooltip: 'Perfil e modos',
              onPressed: onOpenProfile!,
              icon: Icons.person_outline_rounded,
            ),
          _TopBarAction(
            tooltip: 'Atualizar',
            onPressed: onRefresh,
            icon: Icons.refresh_rounded,
          ),
          _TopBarAction(
            tooltip: 'Sair',
            onPressed: onSignedOut ?? context.read<ManagementSession>().signOut,
            icon: Icons.logout_rounded,
          ),
        ],
        SizedBox(width: compact ? 8 : 14),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: SharedAppColors.stroke),
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: SharedAppColors.card,
          foregroundColor: SharedAppColors.muted,
          side: const BorderSide(color: SharedAppColors.stroke),
          minimumSize: const Size(40, 40),
        ),
      ),
    );
  }
}

class _ManagementPageContent extends StatelessWidget {
  const _ManagementPageContent({
    required this.children,
    required this.horizontalPadding,
  });

  final List<Widget> children;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          18,
          horizontalPadding,
          36,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      );
}

class _ManagementSideNavigation extends StatelessWidget {
  const _ManagementSideNavigation({
    required this.tabs,
    required this.selectedIndex,
    required this.extended,
    required this.onSelected,
  });

  final List<_ManagementTab> tabs;
  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: SharedAppColors.card,
          border: Border(
            right: BorderSide(color: SharedAppColors.stroke),
          ),
        ),
        child: NavigationRail(
          selectedIndex: selectedIndex,
          extended: extended,
          minWidth: 82,
          minExtendedWidth: 220,
          groupAlignment: -.72,
          backgroundColor: SharedAppColors.card,
          indicatorColor: SharedAppColors.orange.withOpacity(.14),
          selectedIconTheme: const IconThemeData(color: SharedAppColors.orange),
          unselectedIconTheme:
              const IconThemeData(color: SharedAppColors.muted),
          selectedLabelTextStyle: const TextStyle(
            color: SharedAppColors.text,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelTextStyle:
              const TextStyle(color: SharedAppColors.muted),
          onDestinationSelected: onSelected,
          destinations: [
            for (final tab in tabs)
              NavigationRailDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: Text(tab.label),
              ),
          ],
        ),
      );
}

class _ManagementBottomNavigation extends StatelessWidget {
  const _ManagementBottomNavigation({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ManagementTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: SharedAppColors.background,
          border: Border(
            top: BorderSide(color: SharedAppColors.stroke),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            destinations: [
              for (final tab in tabs)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.label,
                ),
            ],
          ),
        ),
      );
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
    title: 'Solicitações recebidas',
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
    title: 'Solicitações recebidas',
    icon: Icons.inbox_outlined,
    selectedIcon: Icons.inbox_rounded,
    child: _BookingRequestsPage(adminView: true),
  ),
  _ManagementTab(
    label: 'Painel',
    title: 'Painel administrativo',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    child: _AdminDashboardPage(),
  ),
  _ManagementTab(
    label: 'Agenda',
    title: 'Agenda por barbeiro',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    child: _BarberAgendaPage(adminView: true),
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
  _ManagementTab(
    label: 'Config',
    title: 'Configuração da barbearia',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    child: _SettingsPage(),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded = constraints.maxWidth < 520;
        return Container(
          width: expanded ? double.infinity : null,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: SharedAppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SharedAppColors.stroke),
          ),
          child: SegmentedButton<ManagementRole>(
            segments: const [
              ButtonSegment(
                value: ManagementRole.barber,
                label: Text('Barbeiro'),
                icon: Icon(Icons.content_cut_rounded),
              ),
              ButtonSegment(
                value: ManagementRole.admin,
                label: Text('Dono'),
                icon: Icon(Icons.storefront_rounded),
              ),
            ],
            selected: {selectedRole},
            onSelectionChanged: (value) => onChanged(value.first),
            showSelectedIcon: false,
            expandedInsets: expanded ? EdgeInsets.zero : null,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              minimumSize: WidgetStateProperty.all(
                Size(expanded ? 0 : 112, 40),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? SharedAppColors.orange
                    : Colors.transparent,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? SharedAppColors.onGold
                    : SharedAppColors.muted,
              ),
              side: WidgetStateProperty.all(BorderSide.none),
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            selectedIcon: const Icon(Icons.check_rounded),
            multiSelectionEnabled: false,
            emptySelectionAllowed: false,
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isAdmin,
    required this.title,
  });

  final bool isAdmin;
  final String title;

  @override
  Widget build(BuildContext context) {
    final logoUrl =
        context.watch<ManagementSession>().shopConfiguration?.logoUrl.trim() ??
            '';
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          padding: EdgeInsets.all(compact ? 18 : 22),
          decoration: BoxDecoration(
            color: SharedAppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SharedAppColors.stroke),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: compact ? 50 : 58,
                height: compact ? 50 : 58,
                decoration: BoxDecoration(
                  color: SharedAppColors.elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SharedAppColors.stroke),
                ),
                clipBehavior: Clip.antiAlias,
                child: logoUrl.isEmpty
                    ? const Icon(
                        Icons.storefront_rounded,
                        color: SharedAppColors.orange,
                      )
                    : Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.storefront_rounded,
                          color: SharedAppColors.orange,
                        ),
                      ),
              ),
              SizedBox(width: compact ? 14 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdmin ? 'VISÃO DA BARBEARIA' : 'MINHA OPERAÇÃO',
                      style: const TextStyle(
                        color: SharedAppColors.orange,
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: compact
                          ? Theme.of(context).textTheme.headlineSmall
                          : Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isAdmin
                          ? 'Equipe, serviços, caixa e desempenho em um só lugar.'
                          : 'Pedidos, agenda, horários e comissão do seu dia.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
