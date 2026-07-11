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
  late final Animation<double> _slashProgress;
  late final Animation<double> _razorOpacity;
  late final Animation<double> _razorScale;
  late final Animation<double> _crownOpacity;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _sloganOpacity;
  late final Animation<double> _sceneOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _slashProgress = _interval(.15, .35);
    _razorOpacity = _interval(.30, .52);
    _razorScale = Tween<double>(begin: .90, end: 1).animate(
      _interval(.30, .52, curve: Curves.easeOutBack),
    );
    _crownOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 45),
    ]).animate(_interval(.50, .74));
    _logoOpacity = _interval(.68, .84);
    _logoScale = Tween<double>(begin: .96, end: 1).animate(
      _interval(.68, .84, curve: Curves.easeOutCubic),
    );
    _sloganOpacity = _interval(.84, .92);
    _sceneOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 92),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 8),
    ]).animate(_controller);
    _start();
  }

  Animation<double> _interval(
    double begin,
    double end, {
    Curve curve = Curves.easeOutCubic,
  }) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: curve),
    );
  }

  Future<void> _start() async {
    final prefsFuture = SharedPreferences.getInstance();
    final dataFuture = context.read<AppState>().loadInitialData();
    final resultsFuture = Future.wait<Object?>([
      prefsFuture,
      dataFuture,
    ]);
    await _controller.forward();
    final results = await resultsFuture;

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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final logoWidth =
                        (constraints.maxWidth * .78).clamp(250.0, 410.0);

                    return Opacity(
                      opacity: _sceneOpacity.value,
                      child: Center(
                        child: SizedBox(
                          width: logoWidth,
                          height: logoWidth * .92,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: (1 - _logoOpacity.value) *
                                    _slashProgress.value,
                                child: CustomPaint(
                                  size: Size(logoWidth * .72, 70),
                                  painter: _GoldenSlashPainter(
                                    progress: _slashProgress.value,
                                  ),
                                ),
                              ),
                              Opacity(
                                opacity: (1 - _logoOpacity.value) *
                                    _razorOpacity.value,
                                child: Transform.scale(
                                  scale: _razorScale.value,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.brandYellow
                                              .withOpacity(.22),
                                          blurRadius: 34,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipRect(
                                      child: Align(
                                        widthFactor: .27,
                                        alignment: Alignment.centerRight,
                                        child: Image.asset(
                                          AppConstants.brandLogoOfficial,
                                          width: logoWidth,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Opacity(
                                opacity: _crownOpacity.value,
                                child: Image.asset(
                                  AppConstants.brandCrownOfficial,
                                  width: logoWidth * .32,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                              Opacity(
                                opacity: _logoOpacity.value,
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: Semantics(
                                    image: true,
                                    label: 'Clube da Régua',
                                    child: Image.asset(
                                      AppConstants.brandLogoOfficial,
                                      width: logoWidth,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      excludeFromSemantics: true,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 8,
                                right: 8,
                                child: Opacity(
                                  opacity: _sloganOpacity.value,
                                  child: const _BrandSlogan(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandSlogan extends StatelessWidget {
  const _BrandSlogan();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppColors.text,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.2,
      height: 1.4,
    );

    return Text.rich(
      const TextSpan(
        style: style,
        children: [
          TextSpan(text: 'O SISTEMA FEITO PARA '),
          TextSpan(
            text: 'BARBEARIAS.',
            style: TextStyle(color: AppColors.brandYellow),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _GoldenSlashPainter extends CustomPainter {
  const _GoldenSlashPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(0, size.height * .72);
    final control = Offset(size.width * .48, size.height * .44);
    final end = Offset(size.width, size.height * .20);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    final metric = path.computeMetrics().first;
    final visiblePath = metric.extractPath(0, metric.length * progress);
    final paint = Paint()
      ..color = AppColors.brandYellow
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(visiblePath, paint);
  }

  @override
  bool shouldRepaint(covariant _GoldenSlashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
