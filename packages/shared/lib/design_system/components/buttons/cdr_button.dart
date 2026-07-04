import 'package:flutter/material.dart';

import '../../tokens/cdr_design_tokens.dart';

enum CDRButtonVariant {
  primary,
  secondary,
  outlined,
  ghost,
}

class CDRButton extends StatelessWidget {
  const CDRButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CDRButtonVariant.primary,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.isExpanded = true,
  });

  const CDRButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.isExpanded = true,
  }) : variant = CDRButtonVariant.primary;

  const CDRButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.isExpanded = true,
  }) : variant = CDRButtonVariant.secondary;

  const CDRButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.isExpanded = true,
  }) : variant = CDRButtonVariant.outlined;

  const CDRButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.isExpanded = true,
  }) : variant = CDRButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final CDRButtonVariant variant;
  final Widget? leading;
  final Widget? trailing;
  final bool isLoading;
  final bool isExpanded;

  bool get _isDisabled => onPressed == null;

  @override
  Widget build(BuildContext context) {
    final button = AnimatedContainer(
      duration: CDRDurationTokens.fast,
      constraints: const BoxConstraints(
        minHeight: CDRSizeTokens.buttonHeight,
        minWidth: CDRSizeTokens.buttonMinWidth,
      ),
      child: TextButton(
        onPressed: _isDisabled
            ? null
            : isLoading
                ? () {}
                : onPressed,
        style: _style(),
        child: AnimatedSwitcher(
          duration: CDRDurationTokens.fast,
          child: isLoading ? _loader() : _content(),
        ),
      ),
    );

    if (!isExpanded) return button;

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }

  ButtonStyle _style() {
    return ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        const Size(
          CDRSizeTokens.buttonMinWidth,
          CDRSizeTokens.buttonHeight,
        ),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: CDRSpacingTokens.xl,
          vertical: CDRSpacingTokens.md,
        ),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CDRRadiusTokens.button),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(_backgroundColor),
      foregroundColor: WidgetStateProperty.resolveWith(_foregroundColor),
      overlayColor: WidgetStateProperty.resolveWith(_overlayColor),
      side: WidgetStateProperty.resolveWith(_borderSide),
      textStyle: WidgetStateProperty.all(CDRTypographyTokens.button),
      elevation: WidgetStateProperty.all(0),
      animationDuration: CDRDurationTokens.fast,
    );
  }

  Widget _content() {
    return Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          IconTheme.merge(
            data: const IconThemeData(size: CDRSizeTokens.icon),
            child: leading!,
          ),
          const SizedBox(width: CDRSpacingTokens.sm),
        ],
        Flexible(
          fit: isExpanded ? FlexFit.tight : FlexFit.loose,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: CDRSpacingTokens.sm),
          IconTheme.merge(
            data: const IconThemeData(size: CDRSizeTokens.icon),
            child: trailing!,
          ),
        ],
      ],
    );
  }

  Widget _loader() {
    final color = _foregroundColor({});

    return SizedBox(
      key: const ValueKey('cdr-button-loader'),
      width: CDRSizeTokens.loader,
      height: CDRSizeTokens.loader,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Color _backgroundColor(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return variant == CDRButtonVariant.ghost
          ? Colors.transparent
          : CDRColorTokens.disabledBackground;
    }

    final isPressed = states.contains(WidgetState.pressed);
    final isHovered = states.contains(WidgetState.hovered);

    switch (variant) {
      case CDRButtonVariant.primary:
        if (isPressed) return CDRColorTokens.goldPressed;
        if (isHovered) return CDRColorTokens.goldHover;
        return CDRColorTokens.gold;
      case CDRButtonVariant.secondary:
        if (isPressed) return CDRColorTokens.graphiteLight;
        if (isHovered) return CDRColorTokens.graphiteLight;
        return CDRColorTokens.graphite;
      case CDRButtonVariant.outlined:
        if (isPressed) return CDRColorTokens.graphiteLight;
        if (isHovered) return CDRColorTokens.graphite;
        return Colors.transparent;
      case CDRButtonVariant.ghost:
        if (isPressed) return CDRColorTokens.graphiteLight;
        if (isHovered) return CDRColorTokens.graphite;
        return Colors.transparent;
    }
  }

  Color _foregroundColor(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return CDRColorTokens.disabledForeground;
    }

    switch (variant) {
      case CDRButtonVariant.primary:
        return CDRColorTokens.black;
      case CDRButtonVariant.secondary:
      case CDRButtonVariant.outlined:
      case CDRButtonVariant.ghost:
        return CDRColorTokens.white;
    }
  }

  Color _overlayColor(Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) {
      return CDRColorTokens.gold.withOpacity(0.12);
    }

    if (states.contains(WidgetState.hovered)) {
      return CDRColorTokens.gold.withOpacity(0.08);
    }

    return Colors.transparent;
  }

  BorderSide _borderSide(Set<WidgetState> states) {
    if (variant != CDRButtonVariant.outlined) {
      return BorderSide.none;
    }

    if (states.contains(WidgetState.disabled)) {
      return const BorderSide(color: CDRColorTokens.disabledForeground);
    }

    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.pressed)) {
      return const BorderSide(color: CDRColorTokens.gold);
    }

    return const BorderSide(color: CDRColorTokens.border);
  }
}
