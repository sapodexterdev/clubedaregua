import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';
import '../core/app_mode.dart';
import '../providers/app_mode_controller.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../services/boot_status.dart';
import 'auth/login_screen.dart';
import 'auth/password_recovery_screen.dart';
import 'client/home_screen.dart';
import 'mode_selection_screen.dart';
import 'onboarding_screen.dart';
import 'professional_mode_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.runInitialNavigation = true,
  });

  static const route = '/';
  static const onboardingSeenKey = 'clubedaregua.onboarding.seen';

  @visibleForTesting
  final bool runInitialNavigation;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _displayDuration = Duration(milliseconds: 1760);
  static const _reducedMotionDisplayDuration = Duration(milliseconds: 200);
  static const _exitDuration = Duration(milliseconds: 240);
  static const _reducedMotionExitDuration = Duration(milliseconds: 150);
  static const _slowLoadingDelay = Duration(milliseconds: 2000);

  AnimationController? _sceneController;
  Animation<double> _brandOpacity = const AlwaysStoppedAnimation(1);
  Animation<double> _brandScale = const AlwaysStoppedAnimation(1);
  Animation<double> _sloganOpacity = const AlwaysStoppedAnimation(1);
  Timer? _slowLoadingTimer;

  bool _exiting = false;
  bool _reduceMotion = false;
  bool _sceneStarted = false;
  bool _showSlowLoading = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      final controller = AnimationController(
        vsync: this,
        duration: _displayDuration,
      );
      _sceneController = controller;
      _brandOpacity = CurvedAnimation(
        parent: controller,
        curve: const Interval(.06, .48, curve: Curves.easeOutCubic),
      );
      _brandScale = Tween<double>(begin: .96, end: 1).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(.06, .48, curve: Curves.easeOutCubic),
        ),
      );
      _sloganOpacity = CurvedAnimation(
        parent: controller,
        curve: const Interval(.64, .82, curve: Curves.easeOut),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sceneStarted) return;
    _sceneStarted = true;
    _reduceMotion = MediaQuery.of(context).disableAnimations;

    final controller = _sceneController;
    if (controller != null) {
      if (_reduceMotion) {
        controller.duration = _reducedMotionDisplayDuration;
      }
      unawaited(controller.forward());
      _slowLoadingTimer = Timer(_slowLoadingDelay, () {
        if (!mounted || _exiting) return;
        setState(() => _showSlowLoading = true);
      });
    }

    if (widget.runInitialNavigation) unawaited(_start());
  }

  Future<void> _start() async {
    final openedForPasswordRecovery = _isPasswordRecoveryCallback();
    final prefsFuture = SharedPreferences.getInstance();

    final results = await Future.wait<Object?>([
      prefsFuture,
      Future<void>.delayed(
        kIsWeb
            ? Duration.zero
            : _reduceMotion
                ? _reducedMotionDisplayDuration
                : _displayDuration,
      ),
    ]);

    if (!mounted) return;
    final prefs = results.first as SharedPreferences;
    final state = context.read<AppState>();
    final modes = context.read<AppModeController>();
    if (openedForPasswordRecovery) {
      await _waitForInitialData(state);
      if (!mounted) return;
    }
    final hasSeenOnboarding =
        prefs.getBool(SplashScreen.onboardingSeenKey) ?? false;
    final forceOnboardingPreview =
        kIsWeb && Uri.base.queryParameters['preview'] == 'onboarding';
    final hasTeamInvitation = kIsWeb &&
        Uri.base.queryParameters['team_invite']?.trim().isNotEmpty == true;
    final requestedMode = Uri.base.queryParameters['mode'];
    if (requestedMode == 'client') {
      await prefs.setString(AppModeController.legacyPreferenceKey, 'client');
    }

    String route;
    if (await AuthService().hasPendingPasswordRecovery()) {
      route = PasswordRecoveryScreen.route;
    } else if (hasTeamInvitation) {
      await _waitForInitialData(state);
      if (!mounted) return;
      await _synchronizeMode(state, modes);
      route = state.isSignedIn ? ModeSelectionScreen.route : LoginScreen.route;
    } else if (!hasSeenOnboarding || forceOnboardingPreview) {
      route = OnboardingScreen.route;
    } else {
      await _waitForInitialData(state);
      if (!mounted) return;
      await _synchronizeMode(state, modes);
      if (!mounted) return;
      final mode = modes.currentMode;
      route = mode == AppMode.client
          ? HomeScreen.route
          : ProfessionalModeScreen.routeFor(mode);
    }

    if (!mounted) return;
    if (kIsWeb) {
      Navigator.pushReplacementNamed(context, route);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        hideBootStatus();
      });
      return;
    }

    _slowLoadingTimer?.cancel();
    setState(() => _exiting = true);
    await Future<void>.delayed(
      _reduceMotion ? _reducedMotionExitDuration : _exitDuration,
    );
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

  Future<void> _synchronizeMode(
    AppState state,
    AppModeController modes,
  ) {
    return modes.synchronizeAccess(
      isSignedIn: state.isSignedIn,
      userId: AuthService().currentUser?.id,
      professionalRoles: state.professionalRoles,
    );
  }

  bool _isPasswordRecoveryCallback() {
    if (!kIsWeb || Uri.base.fragment.isEmpty) return false;
    try {
      return Uri.splitQueryString(Uri.base.fragment)['type'] == 'recovery';
    } on FormatException {
      return false;
    }
  }

  @override
  void dispose() {
    _slowLoadingTimer?.cancel();
    _sceneController?.dispose();
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
        duration: reduceMotion ? _reducedMotionExitDuration : _exitDuration,
        curve: Curves.easeOut,
        child: SafeArea(
          minimum: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final protectedWidth = constraints.maxWidth;
              final preferredWidth =
                  (protectedWidth * .76).clamp(260.0, 420.0).toDouble();
              final logoWidth = preferredWidth > protectedWidth
                  ? protectedWidth
                  : preferredWidth;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _sceneController ??
                            const AlwaysStoppedAnimation<double>(1),
                        builder: (context, child) => Opacity(
                          key: const ValueKey('splash-brand-opacity'),
                          opacity: reduceMotion
                              ? _sceneController?.value ?? 1
                              : _brandOpacity.value,
                          child: Transform.scale(
                            key: const ValueKey('splash-brand-scale'),
                            scale: reduceMotion ? 1 : _brandScale.value,
                            child: child,
                          ),
                        ),
                        child: Semantics(
                          image: true,
                          label: 'Clube da Régua',
                          child: SvgPicture.asset(
                            AppConstants.brandV3LogoPrincipal,
                            width: logoWidth,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _sceneController ??
                            const AlwaysStoppedAnimation<double>(1),
                        builder: (context, child) => Opacity(
                          key: const ValueKey('splash-slogan-opacity'),
                          opacity: reduceMotion
                              ? _sceneController?.value ?? 1
                              : _sloganOpacity.value,
                          child: child,
                        ),
                        child: const _SplashSlogan(),
                      ),
                      AnimatedSwitcher(
                        duration: reduceMotion
                            ? _reducedMotionExitDuration
                            : const Duration(milliseconds: 250),
                        child: _showSlowLoading
                            ? const Padding(
                                key: ValueKey('slow-loading'),
                                padding: EdgeInsets.only(top: 32),
                                child: _StaticLoadingStatus(),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashSlogan extends StatelessWidget {
  const _SplashSlogan();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'O SISTEMA FEITO PARA '),
          TextSpan(
            text: 'BARBEARIAS.',
            style: TextStyle(color: Color(0xFFF3B200)),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.2,
        height: 1.4,
      ),
    );
  }
}

class _StaticLoadingStatus extends StatelessWidget {
  const _StaticLoadingStatus();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'O aplicativo ainda está carregando',
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFF3B200),
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: 6),
          ),
          SizedBox(width: 12),
          Text(
            'CARREGANDO...',
            style: TextStyle(
              color: Color(0xFFA1A1AA),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
