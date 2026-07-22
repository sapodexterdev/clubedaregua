import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'client/home_screen.dart';
import 'mode_selection_screen.dart';

class AppEntryGateScreen extends StatefulWidget {
  const AppEntryGateScreen({super.key});

  static const route = '/entry';

  @override
  State<AppEntryGateScreen> createState() => _AppEntryGateScreenState();
}

class _AppEntryGateScreenState extends State<AppEntryGateScreen> {
  var _navigated = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isLoading && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          state.isSignedIn && state.hasProfessionalAccess
              ? ModeSelectionScreen.route
              : HomeScreen.route,
        );
      });
    }

    return const Scaffold(
      backgroundColor: AppColors.background,
      body: CDRLoading.fullScreen(
        message: 'Preparando sua experiência...',
      ),
    );
  }
}
