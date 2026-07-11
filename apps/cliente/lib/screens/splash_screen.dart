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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _scale = Tween<double>(begin: .98, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _start();
  }

  Future<void> _start() async {
    final prefsFuture = SharedPreferences.getInstance();
    final dataFuture = context.read<AppState>().loadInitialData();
    final minimumDisplayFuture = Future<void>.delayed(
      const Duration(milliseconds: 1600),
    );

    await _controller.forward();
    final results = await Future.wait<Object?>([
      prefsFuture,
      dataFuture,
      minimumDisplayFuture,
    ]);

    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;

    final prefs = results.first as SharedPreferences;
    final hasSeenOnboarding =
        prefs.getBool(SplashScreen.onboardingSeenKey) ?? false;
    Navigator.pushReplacementNamed(
      context,
      hasSeenOnboarding ? HomeScreen.route : OnboardingScreen.route,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: .82,
                    colors: [
                      Color(0xFF18181B),
                      Color(0xFF09090B),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Opacity(
                    opacity: _opacity.value,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final logoWidth =
                              (constraints.maxWidth * .82).clamp(240.0, 420.0);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Semantics(
                                  image: true,
                                  label: 'Clube da Régua',
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.brandYellow
                                              .withOpacity(.14),
                                          blurRadius: 40,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      AppConstants.brandLogoOfficial,
                                      width: logoWidth,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      excludeFromSemantics: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const Text(
                                  'Tecnologia que eleva o nível da sua barbearia.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: .8,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
