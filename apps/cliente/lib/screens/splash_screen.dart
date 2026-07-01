import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'client/home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const route = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _routeFromSession();
  }

  Future<void> _routeFromSession() async {
    await Future.delayed(const Duration(milliseconds: 900));
    final session = await AuthService().restoreSession();

    if (!mounted) return;
    if (session != null) {
      await context.read<AppState>().loadInitialData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, HomeScreen.route);
      return;
    }

    Navigator.pushReplacementNamed(context, OnboardingScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Clube da Régua',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
