import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';
import '../providers/app_state.dart';
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
    with TickerProviderStateMixin {
  static const _minimumDuration = Duration(milliseconds: 1800);
  static const _exitDuration = Duration(milliseconds: 240);

  late final AnimationController _pulseController;
  late final AnimationController _backgroundController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseGlow;
  late final Animation<double> _backgroundScale;

  bool _exiting = false;
  bool _backgroundPrecached = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
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
        tween: const ConstantTween<double>(1),
        weight: 55,
      ),
    ]).animate(_pulseController);

    _pulseGlow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: .10, end: .30), weight: 10),
      TweenSequenceItem(tween: Tween(begin: .30, end: .12), weight: 9),
      TweenSequenceItem(tween: Tween(begin: .12, end: .24), weight: 9),
      TweenSequenceItem(tween: Tween(begin: .24, end: .10), weight: 17),
      TweenSequenceItem(
        tween: const ConstantTween<double>(.10),
        weight: 55,
      ),
    ]).animate(_pulseController);

    _backgroundScale = Tween<double>(begin: 1.02, end: 1.065).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat();
    _backgroundController.forward();
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
    final dataFuture = context.read<AppState>().loadInitialData();

    final results = await Future.wait<Object?>([
      prefsFuture,
      dataFuture,
      Future<void>.delayed(_minimumDuration),
    ]);

    if (!mounted) return;

    setState(() => _exiting = true);
    await Future<void>.delayed(_exitDuration);

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
    _pulseController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Transform.scale(
                  scale: reduceMotion ? 1.02 : _backgroundScale.value,
                  child: child,
                );
              },
              child: Image.asset(
                AppConstants.splashV3UrbanBarbershop,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -.08),
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
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
