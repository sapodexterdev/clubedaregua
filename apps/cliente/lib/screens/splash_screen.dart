import 'dart:ui' show ImageFilter;

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
  late final Animation<double> _slashOpacity;
  late final Animation<double> _razorOpacity;
  late final Animation<double> _razorScale;
  late final Animation<double> _crownOpacity;
  late final Animation<double> _sparkleOpacity;
  late final Animation<double> _sparkleScale;
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
    _slashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 50),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 35),
    ]).animate(_interval(.15, .43, curve: Curves.linear));
    _razorOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 40),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 30),
    ]).animate(_interval(.26, .55, curve: Curves.linear));
    _razorScale = Tween<double>(begin: .90, end: 1).animate(
      _interval(.30, .52, curve: Curves.easeOutBack),
    );
    _sparkleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 40),
    ]).animate(_interval(.35, .54, curve: Curves.easeOut));
    _sparkleScale = Tween<double>(begin: .25, end: 1.25).animate(
      _interval(.35, .48, curve: Curves.easeOutBack),
    );
    _crownOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 45),
    ]).animate(_interval(.55, .78));
    _logoOpacity = _interval(.74, .86);
    _logoScale = Tween<double>(begin: .96, end: 1).animate(
      _interval(.74, .86, curve: Curves.easeOutCubic),
    );
    _sloganOpacity = _interval(.84, .94);
    _sceneOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 94),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 6),
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
              const ColoredBox(color: Color(0xFF000000)),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final logoWidth =
                        (constraints.maxWidth * .82).clamp(270.0, 420.0);

                    return Opacity(
                      opacity: _sceneOpacity.value,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: Opacity(
                              opacity: _slashOpacity.value,
                              child: CustomPaint(
                                size: Size(constraints.maxWidth * .78, 80),
                                painter: _GoldenSlashPainter(
                                  progress: _slashProgress.value,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Opacity(
                              opacity: _razorOpacity.value,
                              child: Transform.rotate(
                                angle: .42,
                                child: Transform.scale(
                                  scale: _razorScale.value,
                                  child: _RazorStage(
                                    width: logoWidth * .36,
                                    sparkleOpacity: _sparkleOpacity.value,
                                    sparkleScale: _sparkleScale.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Opacity(
                              opacity: _crownOpacity.value,
                              child: Transform.scale(
                                scale: .84 + (_crownOpacity.value * .16),
                                child: _GlowAsset(
                                  asset: AppConstants.brandCrownOfficial,
                                  width: logoWidth * .32,
                                  glowOpacity: .16,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: SizedBox(
                              width: logoWidth,
                              height: logoWidth * .88,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
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
                        ],
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
    final glowPaint = Paint()
      ..color = AppColors.brandYellow.withOpacity(.24)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.stroke;
    final paint = Paint()
      ..color = AppColors.brandYellow
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(visiblePath, glowPaint);
    canvas.drawPath(visiblePath, paint);
  }

  @override
  bool shouldRepaint(covariant _GoldenSlashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _GlowAsset extends StatelessWidget {
  const _GlowAsset({
    required this.asset,
    required this.width,
    required this.glowOpacity,
  });

  final String asset;
  final double width;
  final double glowOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Opacity(
            opacity: glowOpacity,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                AppColors.brandYellow,
                BlendMode.srcIn,
              ),
              child: Image.asset(asset, width: width),
            ),
          ),
        ),
        Image.asset(
          asset,
          width: width,
          filterQuality: FilterQuality.high,
        ),
      ],
    );
  }
}

class _RazorStage extends StatelessWidget {
  const _RazorStage({
    required this.width,
    required this.sparkleOpacity,
    required this.sparkleScale,
  });

  final double width;
  final double sparkleOpacity;
  final double sparkleScale;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.654;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: _GlowAsset(
              asset: AppConstants.brandRazorOfficial,
              width: width,
              glowOpacity: .20,
            ),
          ),
          Positioned(
            left: width * .60,
            top: height * .43,
            child: Opacity(
              opacity: sparkleOpacity,
              child: Transform.scale(
                scale: sparkleScale,
                child: const CustomPaint(
                  size: Size(58, 58),
                  painter: _RazorSparklePainter(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RazorSparklePainter extends CustomPainter {
  const _RazorSparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final glow = Paint()
      ..color = AppColors.brandYellow.withOpacity(.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawCircle(center, 10, glow);

    final rays = Paint()
      ..color = const Color(0xFFFFE7A0)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;
    canvas
      ..drawLine(Offset(center.dx, 3), Offset(center.dx, size.height - 3), rays)
      ..drawLine(Offset(3, center.dy), Offset(size.width - 3, center.dy), rays)
      ..drawLine(const Offset(10, 10), const Offset(48, 48), rays)
      ..drawLine(const Offset(48, 10), const Offset(10, 48), rays);
    canvas.drawCircle(center, 4.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
