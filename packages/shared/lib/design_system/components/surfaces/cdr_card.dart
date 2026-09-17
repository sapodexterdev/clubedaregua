import 'package:flutter/material.dart';

import '../../tokens/cdr_design_tokens.dart';

class CDRCard extends StatelessWidget {
  const CDRCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CDRSpacingTokens.lg),
    this.margin,
    this.onTap,
    this.semanticLabel,
    this.backgroundColor = CDRColorTokens.graphite,
    this.borderColor = CDRColorTokens.border,
    this.borderRadius = CDRRadiusTokens.large,
    this.clipBehavior = Clip.antiAlias,
  });

  const CDRCard.elevated({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CDRSpacingTokens.lg),
    this.margin,
    this.onTap,
    this.semanticLabel,
    this.backgroundColor = CDRColorTokens.graphiteLight,
    this.borderColor = CDRColorTokens.border,
    this.borderRadius = CDRRadiusTokens.large,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final content = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: clipBehavior,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(padding: padding, child: child),
            ),
    );

    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: margin == null
          ? content
          : Padding(padding: margin!, child: content),
    );
  }
}
