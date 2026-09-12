import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_mode.dart';
import '../../core/auth_return_intent.dart';
import '../../providers/app_mode_controller.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/premium_bottom_nav.dart';
import '../auth/login_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

enum ClientRootTab { discover, favorites, agenda, profile }

final clientRootRouteObserver = RouteObserver<ModalRoute<dynamic>>();

class ClientShell extends StatefulWidget {
  const ClientShell({
    this.initialTab = ClientRootTab.discover,
    super.key,
  });

  final ClientRootTab initialTab;

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> with RouteAware {
  late int _currentIndex = widget.initialTab.index;
  late final Set<int> _visitedIndexes = {_currentIndex};
  var _initialGuardResolved = false;
  ModalRoute<dynamic>? _subscribedRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        clientRootRouteObserver.unsubscribe(this);
      }
      _subscribedRoute = route;
      if (route != null) {
        clientRootRouteObserver.subscribe(this, route);
      }
    }
    if (_initialGuardResolved) return;
    _initialGuardResolved = true;
    if (_currentIndex != ClientRootTab.discover.index &&
        !context.read<AppState>().isSignedIn) {
      final requestedIndex = _currentIndex;
      _currentIndex = ClientRootTab.discover.index;
      _visitedIndexes
        ..clear()
        ..add(_currentIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openLoginFor(requestedIndex);
      });
    }
  }

  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncRoute(_currentIndex);
    });
  }

  @override
  void dispose() {
    clientRootRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClientShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _currentIndex = widget.initialTab.index;
      _visitedIndexes.add(_currentIndex);
    }
  }

  Future<void> _selectTab(int index) async {
    if (index < 0 || index >= ClientRootTab.values.length) return;
    if (index == _currentIndex) return;

    final state = context.read<AppState>();
    if (index != ClientRootTab.discover.index && !state.isSignedIn) {
      await _openLoginFor(index);
      return;
    }

    final selected =
        await context.read<AppModeController>().selectMode(AppMode.client);
    if (!selected || !mounted) return;
    setState(() {
      _currentIndex = index;
      _visitedIndexes.add(index);
    });
    _syncRoute(index);
  }

  Future<void> _openLoginFor(int index) async {
    await Navigator.pushNamed(
      context,
      LoginScreen.route,
      arguments: AuthReturnIntent(
        route: _routeForIndex(index),
        onAuthenticated: () => _selectTab(index),
      ),
    );
    if (mounted && !context.read<AppState>().isSignedIn) {
      _syncRoute(ClientRootTab.discover.index);
    }
  }

  void _syncRoute(int index) {
    SystemNavigator.routeInformationUpdated(
      uri: Uri(path: _routeForIndex(index)),
      replace: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AppState>().isSignedIn;
    final visibleIndex =
        isSignedIn ? _currentIndex : ClientRootTab.discover.index;
    if (!isSignedIn &&
        (_currentIndex != ClientRootTab.discover.index ||
            _visitedIndexes.length > 1)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || context.read<AppState>().isSignedIn) return;
        setState(() {
          _currentIndex = ClientRootTab.discover.index;
          _visitedIndexes
            ..clear()
            ..add(_currentIndex);
        });
        _syncRoute(ClientRootTab.discover.index);
      });
    }
    final routeArgument = ModalRoute.of(context)?.settings.arguments;
    final returnsToProfessional = routeArgument is AppMode &&
        routeArgument != AppMode.client &&
        Navigator.canPop(context);
    if (returnsToProfessional) {
      return const _ProfessionalProfileFrame(
        child: ProfileScreen(
          showBottomNavigation: false,
          showBackButton: true,
        ),
      );
    }
    final shell = PopScope(
      canPop: visibleIndex == ClientRootTab.discover.index,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && visibleIndex != ClientRootTab.discover.index) {
          _selectTab(ClientRootTab.discover.index);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: List.generate(ClientRootTab.values.length, (index) {
            if (!_visitedIndexes.contains(index)) {
              return const SizedBox.shrink();
            }
            final active = index == visibleIndex;
            return Offstage(
              offstage: !active,
              child: TickerMode(
                enabled: active,
                child: _buildPage(index, active: active),
              ),
            );
          }),
        ),
        bottomNavigationBar: PremiumBottomNav(
          currentIndex: visibleIndex,
          onTap: _selectTab,
        ),
      ),
    );

    if (context.watch<AppModeController>().currentMode == AppMode.client) {
      return shell;
    }
    return _ProfessionalProfileFrame(child: shell);
  }

  static String _routeForIndex(int index) => switch (index) {
        1 => FavoritesScreen.route,
        2 => HistoryScreen.route,
        3 => ProfileScreen.route,
        _ => HomeScreen.route,
      };

  Widget _buildPage(int index, {required bool active}) => switch (index) {
        0 => HomeScreen(
            key: const PageStorageKey('client-discover'),
            onTabSelected: _selectTab,
            isActive: active,
          ),
        1 => FavoritesScreen(
            key: const PageStorageKey('client-favorites'),
            onTabSelected: _selectTab,
          ),
        2 => HistoryScreen(
            key: const PageStorageKey('client-agenda'),
            onTabSelected: _selectTab,
            isActive: active,
          ),
        3 => ProfileScreen(
            key: const PageStorageKey('client-profile'),
            onTabSelected: _selectTab,
          ),
        _ => const SizedBox.shrink(),
      };
}

class _ProfessionalProfileFrame extends StatelessWidget {
  const _ProfessionalProfileFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 520) return child;
        final availableHeight = constraints.maxHeight;
        final height = availableHeight < 676
            ? availableHeight
            : (availableHeight - 36).clamp(640.0, 900.0).toDouble();
        return ColoredBox(
          color: AppColors.softBackground,
          child: Center(
            child: Container(
              width: 430,
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(44),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(430, height),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
