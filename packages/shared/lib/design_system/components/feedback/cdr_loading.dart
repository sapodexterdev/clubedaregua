import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../tokens/cdr_design_tokens.dart';

enum CDRLoadingVariant { fullScreen, section, compact }

class CDRLoading extends StatefulWidget {
  const CDRLoading.fullScreen({
    super.key,
    this.message,
    this.logoAsset = 'assets/images/brand_v3_segunda_logo.svg',
    this.backgroundAsset = 'assets/images/splash_v3_loading_v2.png',
  })  : variant = CDRLoadingVariant.fullScreen,
        height = double.infinity,
        size = 132;

  const CDRLoading.section({
    super.key,
    this.message,
    this.height = 148,
    this.logoAsset = 'assets/images/brand_v3_segunda_logo.svg',
    this.backgroundAsset = 'assets/images/splash_v3_loading_v2.png',
  })  : variant = CDRLoadingVariant.section,
        size = 72;

  const CDRLoading.compact({
    super.key,
    this.size = 30,
    this.logoAsset = 'assets/images/brand_v3_segunda_logo.svg',
  })  : variant = CDRLoadingVariant.compact,
        message = null,
        backgroundAsset = null,
        height = 0;

  final CDRLoadingVariant variant;
  final String? message;
  final String logoAsset;
  final String? backgroundAsset;
  final double height;
  final double size;

  @override
  State<CDRLoading> createState() => _CDRLoadingState();
}

class _CDRLoadingState extends State<CDRLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: .96, end: 1.04)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: .96)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 50,
      ),
    ]).animate(_controller);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: .34, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: .34), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (widget.variant == CDRLoadingVariant.compact) {
      return _animatedLogo(reduceMotion, compact: true);
    }

    final content = Stack(
      fit: StackFit.expand,
      children: [
        if (widget.backgroundAsset != null)
          Image.asset(
            widget.backgroundAsset!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xA6000000),
                Color(0x70000000),
                Color(0xE609090B),
              ],
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _animatedLogo(reduceMotion),
              if (widget.message != null) ...[
                const SizedBox(height: CDRSpacingTokens.lg),
                Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CDRColorTokens.gray,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (widget.variant == CDRLoadingVariant.fullScreen) return content;
    return ClipRRect(
      borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
      child: SizedBox(height: widget.height, child: content),
    );
  }

  Widget _animatedLogo(bool reduceMotion, {bool compact = false}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: reduceMotion ? 1 : _opacity.value,
        child: Transform.scale(
          scale: reduceMotion ? 1 : _scale.value,
          child: child,
        ),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        padding: EdgeInsets.all(compact ? 5 : 0),
        decoration: compact
            ? BoxDecoration(
                color: CDRColorTokens.night,
                borderRadius: BorderRadius.circular(widget.size * .32),
                border: Border.all(color: CDRColorTokens.border),
              )
            : null,
        child: SvgPicture.asset(widget.logoAsset, fit: BoxFit.contain),
      ),
    );
  }
}
