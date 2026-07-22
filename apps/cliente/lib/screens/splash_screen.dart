import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';
import '../providers/app_state.dart';
import 'client/home_screen.dart';
import 'mode_selection_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const route = '/';
  static const onboardingSeenKey = 'clubedaregua.onboarding.seen';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _displayDuration = Duration(milliseconds: 1760);
  static const _exitDuration = Duration(milliseconds: 240);

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseGlow;

  bool _exiting = false;
  bool _backgroundPrecached = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1.055)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.055, end: .985)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 9,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: .985, end: 1.032)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 9,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.032, end: 1)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 17,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: 55,
      ),
    ]).animate(_pulseController);

    _pulseGlow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: .10, end: .30), weight: 10),
      TweenSequenceItem(tween: Tween(begin: .30, end: .12), weight: 9),
      TweenSequenceItem(tween: Tween(begin: .12, end: .24), weight: 9),
      TweenSequenceItem(tween: Tween(begin: .24, end: .10), weight: 17),
      TweenSequenceItem(
        tween: ConstantTween<double>(.10),
        weight: 55,
      ),
    ]).animate(_pulseController);

    _pulseController.repeat();
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_backgroundPrecached) return;
    _backgroundPrecached = true;
    precacheImage(
      const AssetImage(AppConstants.splashV3UrbanBarbershop),
      context,
    );
  }

  Future<void> _start() async {
    final prefsFuture = SharedPreferences.getInstance();

    final results = await Future.wait<Object?>([
      prefsFuture,
      Future<void>.delayed(kIsWeb ? Duration.zero : _displayDuration),
    ]);

    final prefs = results.first as SharedPreferences;
    final hasSeenOnboarding =
        prefs.getBool(SplashScreen.onboardingSeenKey) ?? false;
    final forceOnboardingPreview = kIsWeb &&
        Uri.base.queryParameters['preview'] == 'onboarding';

    String route;
    if (!hasSeenOnboarding || forceOnboardingPreview) {
      route = OnboardingScreen.route;
    } else {
      final state = context.read<AppState>();
      await _waitForInitialData(state);
      if (!mounted) return;
      route = state.isSignedIn && state.hasProfessionalAccess
          ? ModeSelectionScreen.route
          : HomeScreen.route;
    }

    if (!mounted) return;
    if (kIsWeb) {
      Navigator.pushReplacementNamed(context, route);
      return;
    }

    setState(() => _exiting = true);
    await Future<void>.delayed(_exitDuration);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _waitForInitialData(AppState state) async {
    if (!state.isLoading) return;

    final ready = Completer<void>();
    void listener() {
      if (!state.isLoading && !ready.isCompleted) ready.complete();
    }

    state.addListener(listener);
    try {
      await ready.future.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // Abre o app mesmo se um serviço externo demorar além do esperado.
    } finally {
      state.removeListener(listener);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: SizedBox.expand(),
      );
    }

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: AnimatedOpacity(
        opacity: _exiting ? 0 : 1,
        duration: _exitDuration,
        curve: Curves.easeOut,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppConstants.splashV3UrbanBarbershop),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            const _CinematicOverlay(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final logoWidth = (constraints.maxWidth * .34)
                      .clamp(112.0, 164.0)
                      .toDouble();

                  return Align(
                    alignment: const Alignment(0, -.72),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        final scale = reduceMotion ? 1.0 : _pulseScale.value;
                        final glow = reduceMotion ? .10 : _pulseGlow.value;

                        return Transform.scale(
                          scale: scale,
                          child: _PulsingSecondaryLogo(
                            width: logoWidth,
                            glowOpacity: glow,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CinematicOverlay extends StatelessWidget {
  const _CinematicOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x80000000),
            Color(0x38000000),
            Color(0x52000000),
            Color(0xC4050505),
          ],
          stops: [0, .34, .68, 1],
        ),
      ),
    );
  }
}

class _PulsingSecondaryLogo extends StatelessWidget {
  const _PulsingSecondaryLogo({
    required this.width,
    required this.glowOpacity,
  });

  final double width;
  final double glowOpacity;

  @override
  Widget build(BuildContext context) {
    final logo = SvgPicture.asset(
      AppConstants.brandV3SecondaryLogo,
      width: width,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );

    return Semantics(
      image: true,
      label: 'Clube da Régua carregando',
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Opacity(
              opacity: glowOpacity,
              child: SvgPicture.asset(
                AppConstants.brandV3SecondaryLogo,
                width: width * 1.035,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ),
          logo,
        ],
      ),
    );
  }
}
