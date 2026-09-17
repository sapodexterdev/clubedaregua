part of 'management.dart';

enum ManagementRole { barber, admin }

enum ManagementDestinationId {
  requests,
  dashboard,
  schedule,
  availability,
  clients,
  commission,
  services,
  team,
  commerce,
  settings,
}

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
  final FocusNode _pageTitleFocusNode = FocusNode(
    debugLabel: 'management-page-title',
  );
  final Map<ManagementRole, ManagementDestinationId> _selectedDestinations = {
    ManagementRole.barber: ManagementDestinationId.schedule,
    ManagementRole.admin: ManagementDestinationId.dashboard,
  };

  @override
  void initState() {
    super.initState();
    selectedRole = widget.initialRole ?? ManagementRole.barber;
  }

  @override
  void didUpdateWidget(covariant ManagementHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextRole = widget.initialRole;
    if (nextRole == null || nextRole == oldWidget.initialRole) return;
    selectedRole = nextRole;
    unawaited(context.read<ManagementSession>().activateRole(nextRole));
  }

  @override
  void dispose() {
    _pageTitleFocusNode.dispose();
    super.dispose();
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
    final selectedDestination = _destinationFor(effectiveRole, tabs);
    final page = tabs.firstWhere((tab) => tab.id == selectedDestination);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideNavigation = constraints.maxWidth >= 600;
        final extendedNavigation = constraints.maxWidth >= 1024;
        final horizontalPadding = constraints.maxWidth >= 1024
            ? 32.0
            : useSideNavigation
                ? 24.0
                : 16.0;
        final fallbackDestination = _fallbackDestination(effectiveRole);
        final isAtFallback = selectedDestination == fallbackDestination;
        return PopScope(
          canPop: isAtFallback,
          onPopInvoked: (didPop) {
            if (!didPop && !isAtFallback) {
              _selectDestination(effectiveRole, fallbackDestination);
            }
          },
          child: Scaffold(
            backgroundColor: SharedAppColors.background,
            appBar: _ManagementTopBar(
              title: page.title,
              titleFocusNode: _pageTitleFocusNode,
              onOpenProfile: widget.onOpenProfile,
              onRefresh: () => _refreshCurrentDestination(
                effectiveRole,
                selectedDestination,
              ),
              onSignedOut: widget.onSignedOut,
            ),
            bottomNavigationBar: useSideNavigation
                ? null
                : _ManagementBottomNavigation(
                    tabs: tabs,
                    selectedDestination: selectedDestination,
                    ownerMode: isAdmin,
                    onSelected: (destination) => _selectDestination(
                      effectiveRole,
                      destination,
                    ),
                    onOpenMore: () => _openMoreDestinations(
                      effectiveRole,
                      selectedDestination,
                    ),
                  ),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (useSideNavigation)
                  _ManagementSideNavigation(
                    tabs: tabs,
                    selectedDestination: selectedDestination,
                    extended: extendedNavigation,
                    onSelected: (destination) => _selectDestination(
                      effectiveRole,
                      destination,
                    ),
                  ),
                Expanded(
                  child: _ManagementPageContent(
                    horizontalPadding: horizontalPadding,
                    children: [
                      if (useSideNavigation) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _AvailabilityStatus(
                            label: isAdmin ? 'MODO DONO' : 'MODO BARBEIRO',
                            color: SharedAppColors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _Header(
                        isAdmin: isAdmin,
                        title: isAdmin
                            ? session.barberShopName ?? 'Barbearia'
                            : session.barberHeaderName,
                        dense: !useSideNavigation,
                      ),
                      SizedBox(height: useSideNavigation ? 24 : 20),
                      page.child,
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ManagementDestinationId _destinationFor(
    ManagementRole role,
    List<_ManagementTab> tabs,
  ) {
    final selected = _selectedDestinations[role];
    if (selected != null && tabs.any((tab) => tab.id == selected)) {
      return selected;
    }
    return tabs.first.id;
  }

  ManagementDestinationId _fallbackDestination(ManagementRole role) =>
      role == ManagementRole.admin
          ? ManagementDestinationId.dashboard
          : ManagementDestinationId.schedule;

  void _selectDestination(
    ManagementRole role,
    ManagementDestinationId destination,
  ) {
    if (_selectedDestinations[role] == destination) return;
    setState(() => _selectedDestinations[role] = destination);
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageTitleFocusNode.canRequestFocus) {
          _pageTitleFocusNode.requestFocus();
        }
      });
    }
    unawaited(
      context.read<ManagementSession>().ensureDataForDestination(
            role,
            destination,
          ),
    );
  }

  Future<void> _refreshCurrentDestination(
    ManagementRole role,
    ManagementDestinationId destination,
  ) =>
      context.read<ManagementSession>().ensureDataForDestination(
            role,
            destination,
            force: true,
          );

  Future<void> _openMoreDestinations(
    ManagementRole role,
    ManagementDestinationId selectedDestination,
  ) async {
    final previousFocus = FocusManager.instance.primaryFocus;
    final selected = await showModalBottomSheet<ManagementDestinationId>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: SharedAppColors.card,
      builder: (sheetContext) => _ManagementMoreSheet(
        tabs: _ownerOverflowTabs,
        selectedDestination: selectedDestination,
      ),
    );
    if (previousFocus?.canRequestFocus ?? false) {
      previousFocus!.requestFocus();
    }
    if (!mounted || selected == null) return;
    _selectDestination(role, selected);
  }
}

class _ManagementTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _ManagementTopBar({
    required this.title,
    required this.titleFocusNode,
    required this.onRefresh,
    this.onOpenProfile,
    this.onSignedOut,
  });

  final String title;
  final FocusNode titleFocusNode;
  final VoidCallback onRefresh;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onSignedOut;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return AppBar(
      toolbarHeight: 72,
      titleSpacing: compact ? 16 : 22,
      backgroundColor: SharedAppColors.background,
      title: Row(
        children: [
          Container(
            width: 48,
            height: 48,
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
            child: compact
                ? Semantics(
                    header: true,
                    child: Focus(
                      focusNode: titleFocusNode,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  )
                : Column(
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
                      Semantics(
                        header: true,
                        child: Focus(
                          focusNode: titleFocusNode,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      actions: [
        if (compact)
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
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
              if (onOpenProfile != null)
                const PopupMenuItem(
                  value: 'profile',
                  child: Text('Abrir Perfil'),
                ),
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Atualizar dados'),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Sair')),
            ],
          )
        else ...[
          if (onOpenProfile != null)
            _TopBarAction(
              tooltip: 'Abrir Perfil',
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
          minimumSize: const Size(44, 44),
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
    required this.selectedDestination,
    required this.extended,
    required this.onSelected,
  });

  final List<_ManagementTab> tabs;
  final ManagementDestinationId selectedDestination;
  final bool extended;
  final ValueChanged<ManagementDestinationId> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = tabs.indexWhere(
      (tab) => tab.id == selectedDestination,
    );
    return Container(
      decoration: const BoxDecoration(
        color: SharedAppColors.card,
        border: Border(
          right: BorderSide(color: SharedAppColors.stroke),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final requiredHeight = tabs.length * 64.0 + 24;
          final railHeight = constraints.maxHeight > requiredHeight
              ? constraints.maxHeight
              : requiredHeight;
          return Scrollbar(
            child: SingleChildScrollView(
              child: SizedBox(
                height: railHeight,
                child: NavigationRail(
                  selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                  extended: extended,
                  minWidth: 88,
                  minExtendedWidth: 240,
                  groupAlignment: -1,
                  backgroundColor: SharedAppColors.card,
                  indicatorColor: SharedAppColors.orange.withOpacity(.14),
                  selectedIconTheme:
                      const IconThemeData(color: SharedAppColors.orange),
                  unselectedIconTheme:
                      const IconThemeData(color: SharedAppColors.muted),
                  selectedLabelTextStyle: const TextStyle(
                    color: SharedAppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelTextStyle:
                      const TextStyle(color: SharedAppColors.muted),
                  onDestinationSelected: (index) => onSelected(tabs[index].id),
                  destinations: [
                    for (final tab in tabs)
                      NavigationRailDestination(
                        icon: Tooltip(
                          message: tab.label,
                          child: Icon(tab.icon),
                        ),
                        selectedIcon: Tooltip(
                          message: tab.label,
                          child: Icon(tab.selectedIcon),
                        ),
                        label: Text(tab.label),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ManagementBottomNavigation extends StatelessWidget {
  const _ManagementBottomNavigation({
    required this.tabs,
    required this.selectedDestination,
    required this.ownerMode,
    required this.onSelected,
    required this.onOpenMore,
  });

  final List<_ManagementTab> tabs;
  final ManagementDestinationId selectedDestination;
  final bool ownerMode;
  final ValueChanged<ManagementDestinationId> onSelected;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    final visibleTabs = ownerMode ? _ownerMobileTabs : tabs;
    final moreSelected = ownerMode &&
        _ownerOverflowTabs.any((tab) => tab.id == selectedDestination);
    var selectedIndex = visibleTabs.indexWhere(
      (tab) => tab.id == selectedDestination,
    );
    if (moreSelected) selectedIndex = visibleTabs.length;
    if (selectedIndex < 0) selectedIndex = 0;

    return Container(
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
          onDestinationSelected: (index) {
            if (ownerMode && index == visibleTabs.length) {
              onOpenMore();
              return;
            }
            onSelected(visibleTabs[index].id);
          },
          destinations: [
            for (final tab in visibleTabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
            if (ownerMode)
              const NavigationDestination(
                icon: Icon(Icons.apps_outlined),
                selectedIcon: Icon(Icons.apps_rounded),
                label: 'Mais',
              ),
          ],
        ),
      ),
    );
  }
}

class _ManagementMoreSheet extends StatelessWidget {
  const _ManagementMoreSheet({
    required this.tabs,
    required this.selectedDestination,
  });

  final List<_ManagementTab> tabs;
  final ManagementDestinationId selectedDestination;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mais áreas da Gestão',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    autofocus: true,
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  final selected = tab.id == selectedDestination;
                  return ListTile(
                    selected: selected,
                    selectedColor: SharedAppColors.orange,
                    selectedTileColor: SharedAppColors.orange.withOpacity(.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Icon(selected ? tab.selectedIcon : tab.icon),
                    title: Text(tab.label),
                    subtitle: Text(tab.description),
                    trailing: selected ? const Icon(Icons.check_rounded) : null,
                    onTap: () => Navigator.pop(context, tab.id),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _ManagementTab {
  const _ManagementTab({
    required this.id,
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
    required this.selectedIcon,
    required this.child,
  });

  final ManagementDestinationId id;
  final String label;
  final String title;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
  final Widget child;
}

const _barberTabs = [
  _ManagementTab(
    id: ManagementDestinationId.schedule,
    label: 'Agenda',
    title: 'Agenda do barbeiro',
    description: 'Atendimentos confirmados e operação do dia.',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    child: _BarberAgendaPage(),
  ),
  _ManagementTab(
    id: ManagementDestinationId.availability,
    label: 'Horários',
    title: 'Disponibilidade',
    description: 'Dias e horários disponíveis para agendamento.',
    icon: Icons.schedule_outlined,
    selectedIcon: Icons.schedule_rounded,
    child: _AvailabilityPage(),
  ),
  _ManagementTab(
    id: ManagementDestinationId.clients,
    label: 'Clientes',
    title: 'Clientes atendidos',
    description: 'Histórico de clientes atendidos.',
    icon: Icons.people_alt_outlined,
    selectedIcon: Icons.people_alt_rounded,
    child: _ClientsPage(),
  ),
  _ManagementTab(
    id: ManagementDestinationId.commission,
    label: 'Comissão',
    title: 'Comissão e faturamento',
    description: 'Comissões e desempenho profissional.',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments_rounded,
    child: _CommissionPage(),
  ),
  _ManagementTab(
    id: ManagementDestinationId.requests,
    label: 'Pedidos',
    title: 'Solicitações recebidas',
    description: 'Histórico e triagem operacional.',
    icon: Icons.inbox_outlined,
    selectedIcon: Icons.inbox_rounded,
    child: _BookingRequestsPage(),
  ),
];

const _adminTabs = [
  _ManagementTab(
    id: ManagementDestinationId.dashboard,
    label: 'Painel',
    title: 'Painel da barbearia',
    description: 'Visão geral da operação da barbearia.',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    child: _AdminDashboardPage(),
  ),
  _ManagementTab(
    id: ManagementDestinationId.schedule,
    label: 'Agenda',
    title: 'Agenda por barbeiro',
    description: 'Agenda consolidada por profissional.',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    child: _BarberAgendaPage(adminView: true),
  ),
  _ManagementTab(
    id: ManagementDestinationId.clients,
    label: 'Clientes',
    title: 'Controle de clientes',
    description: 'Clientes, histórico e bloqueios autorizados.',
    icon: Icons.people_alt_outlined,
    selectedIcon: Icons.people_alt_rounded,
    child: _ClientsPage(),
  ),
  _ManagementTab(
    id: ManagementDestinationId.commerce,
    label: 'Caixa',
    title: 'Caixa e estoque',
    description: 'Caixa, produtos, estoque e vendas.',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale_rounded,
    child: _CashPage(),
  ),
  _ManagementTab(
    id: ManagementDestinationId.requests,
    label: 'Pedidos',
    title: 'Solicitações recebidas',
    description: 'Histórico e triagem operacional.',
    icon: Icons.inbox_outlined,
    selectedIcon: Icons.inbox_rounded,
    child: _BookingRequestsPage(adminView: true),
  ),
  _ManagementTab(
    id: ManagementDestinationId.services,
    label: 'Serviços',
    title: 'Cadastro de serviços',
    description: 'Catálogo e regras dos serviços.',
    icon: Icons.design_services_outlined,
    selectedIcon: Icons.design_services_rounded,
    child: _ServicesPage(),
  ),
  _ManagementTab(
    id: ManagementDestinationId.team,
    label: 'Equipe',
    title: 'Cadastro de barbeiros',
    description: 'Profissionais e acessos da unidade.',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge_rounded,
    child: _TeamPage(),
  ),
  _ManagementTab(
    id: ManagementDestinationId.settings,
    label: 'Configurações',
    title: 'Configuração da barbearia',
    description: 'Identidade e regras operacionais.',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    child: _SettingsPage(),
  ),
];

final _ownerMobileTabs = _tabsById(
  _adminTabs,
  const {
    ManagementDestinationId.dashboard,
    ManagementDestinationId.schedule,
    ManagementDestinationId.clients,
    ManagementDestinationId.commerce,
  },
);

final _ownerOverflowTabs = _tabsById(
  _adminTabs,
  const {
    ManagementDestinationId.requests,
    ManagementDestinationId.services,
    ManagementDestinationId.team,
    ManagementDestinationId.settings,
  },
);

List<_ManagementTab> _tabsById(
  List<_ManagementTab> tabs,
  Set<ManagementDestinationId> ids,
) =>
    tabs.where((tab) => ids.contains(tab.id)).toList(growable: false);

class _Header extends StatelessWidget {
  const _Header({
    required this.isAdmin,
    required this.title,
    this.dense = false,
  });

  final bool isAdmin;
  final String title;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final logoUrl =
        context.watch<ManagementSession>().shopConfiguration?.logoUrl.trim() ??
            '';
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = dense || constraints.maxWidth < 520;
        return Container(
          padding: EdgeInsets.all(dense ? 12 : 22),
          decoration: BoxDecoration(
            color: SharedAppColors.card,
            borderRadius: BorderRadius.circular(dense ? 14 : 22),
            border: Border.all(color: SharedAppColors.stroke),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: dense ? 44 : 58,
                height: dense ? 44 : 58,
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
                      dense
                          ? isAdmin
                              ? 'MODO DONO'
                              : 'MODO BARBEIRO'
                          : isAdmin
                              ? 'VISÃO DA BARBEARIA'
                              : 'MINHA OPERAÇÃO',
                      style: const TextStyle(
                        color: SharedAppColors.orange,
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: dense ? 3 : 5),
                    Text(
                      title,
                      maxLines: dense ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: dense
                          ? Theme.of(context).textTheme.titleMedium
                          : compact
                              ? Theme.of(context).textTheme.headlineSmall
                              : Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (!dense) ...[
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
