import 'package:flutter/material.dart';

import '../../tokens/cdr_design_tokens.dart';

enum CDRSkeletonShape { rectangle, circle }

class CDRSkeleton extends StatelessWidget {
  const CDRSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = CDRRadiusTokens.medium,
    this.shape = CDRSkeletonShape.rectangle,
  });

  const CDRSkeleton.line({
    super.key,
    required this.width,
    this.height = 14,
    this.borderRadius = CDRRadiusTokens.small,
  }) : shape = CDRSkeletonShape.rectangle;

  const CDRSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = CDRRadiusTokens.pill,
        shape = CDRSkeletonShape.circle;

  final double width;
  final double height;
  final double borderRadius;
  final CDRSkeletonShape shape;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .58, end: .82),
        duration: reduceMotion ? Duration.zero : CDRDurationTokens.emphasis,
        curve: Curves.easeOut,
        builder: (context, opacity, _) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: CDRColorTokens.graphiteLight.withOpacity(opacity),
            shape: shape == CDRSkeletonShape.circle
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: shape == CDRSkeletonShape.circle
                ? null
                : BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
