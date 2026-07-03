import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'client/home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const route = '/';
  static const onboardingSeenKey = 'clubedaregua.onboarding.seen';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isContinuing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadInitialData();
    });
  }

  Future<void> _continueToDiscovery() async {
    if (_isContinuing) return;
    setState(() => _isContinuing = true);

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding =
        prefs.getBool(SplashScreen.onboardingSeenKey) ?? false;

    if (mounted) await context.read<AppState>().loadInitialData();
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      hasSeenOnboarding ? HomeScreen.route : OnboardingScreen.route,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                AppConstants.splashBarberReference,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              Positioned(
                left: constraints.maxWidth * .09,
                right: constraints.maxWidth * .09,
                top: constraints.maxHeight * .748,
                height: constraints.maxHeight * .075,
                child: Semantics(
                  button: true,
                  label: 'Encontrar barbearias',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      splashColor: AppColors.orange.withOpacity(.16),
                      highlightColor: AppColors.orange.withOpacity(.08),
                      onTap: _continueToDiscovery,
                    ),
                  ),
                ),
              ),
              if (_isContinuing)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
