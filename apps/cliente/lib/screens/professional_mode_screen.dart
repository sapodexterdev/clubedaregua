import 'package:clubedaregua_gestao/management.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_mode.dart';
import '../providers/app_mode_controller.dart';
import '../providers/app_state.dart';
import 'client/home_screen.dart';
import 'client/profile_screen.dart';

class ProfessionalModeScreen extends StatelessWidget {
  const ProfessionalModeScreen({
    required this.mode,
    super.key,
  });

  static const barberRoute = '/professional/barber';
  static const ownerRoute = '/professional/owner';

  final AppMode mode;

  static String routeFor(AppMode mode) => switch (mode) {
        AppMode.barber => barberRoute,
        AppMode.owner => ownerRoute,
        AppMode.client => HomeScreen.route,
      };

  @override
  Widget build(BuildContext context) {
    return EmbeddedManagementArea(
      initialRole:
          mode == AppMode.owner ? ManagementRole.admin : ManagementRole.barber,
      onOpenClientMode: () => _openMode(context, AppMode.client),
      onSignedOut: () => _finishSignOut(context),
      onOpenProfile: () => Navigator.pushNamedAndRemoveUntil(
        context,
        ProfileScreen.route,
        (_) => false,
      ),
      onRoleChanged: (role) async {
        await context.read<AppModeController>().selectMode(
              role == ManagementRole.admin ? AppMode.owner : AppMode.barber,
              notify: false,
            );
      },
    );
  }

  Future<void> _openMode(BuildContext context, AppMode nextMode) async {
    final selected =
        await context.read<AppModeController>().selectMode(nextMode);
    if (!selected || !context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeFor(nextMode),
      (_) => false,
    );
  }

  Future<void> _finishSignOut(BuildContext context) async {
    final appState = context.read<AppState>();
    final modes = context.read<AppModeController>();
    await appState.signOut();
    await modes.resetToClient();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      HomeScreen.route,
      (_) => false,
    );
  }
}
