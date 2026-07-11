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
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 30),
    ]).animate(_interval(.15, .48, curve: Curves.linear));
    _razorOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 45),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 25),
    ]).animate(_interval(.30, .62, curve: Curves.linear));
    _razorScale = Tween<double>(begin: .90, end: 1).animate(
      _interval(.30, .52, curve: Curves.easeOutBack),
    );
    _crownOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 45),
    ]).animate(_interval(.50, .75));
    _logoOpacity = _interval(.70, .84);
    _logoScale = Tween<double>(begin: .96, end: 1).animate(
      _interval(.70, .84, curve: Curves.easeOutCubic),
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
                        (constraints.maxWidth * .76).clamp(250.0, 390.0);

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
                            child: Transform.translate(
                              offset: Offset(-logoWidth * .22, 0),
                              child: Opacity(
                                opacity: _razorOpacity.value,
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
                                    child: ClipPath(
                                      clipper: const _RazorClipper(),
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
                          ),
                          Center(
                            child: Opacity(
                              opacity: _crownOpacity.value,
                              child: Image.asset(
                                AppConstants.brandCrownOfficial,
                                width: logoWidth * .34,
                                filterQuality: FilterQuality.high,
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

class _RazorClipper extends CustomClipper<Path> {
  const _RazorClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * .75, size.height * .12)
      ..lineTo(size.width * .90, size.height * .10)
      ..lineTo(size.width * .95, size.height * .56)
      ..lineTo(size.width, size.height * .63)
      ..lineTo(size.width * .97, size.height * .76)
      ..lineTo(size.width, size.height * .82)
      ..lineTo(size.width * .95, size.height * .84)
      ..lineTo(size.width * .91, size.height * .77)
      ..lineTo(size.width * .80, size.height)
      ..lineTo(size.width * .68, size.height)
      ..lineTo(size.width * .69, size.height * .88)
      ..lineTo(size.width * .91, size.height * .64)
      ..lineTo(size.width * .84, size.height * .53)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
