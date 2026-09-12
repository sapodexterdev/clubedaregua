import 'package:flutter/material.dart';

import '../../tokens/cdr_design_tokens.dart';

enum CDRSnackbarTone { success, warning, error, info, neutral }

class CDRSnackbar {
  const CDRSnackbar._();

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    CDRSnackbarTone tone = CDRSnackbarTone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final color = _toneColor(tone);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CDRColorTokens.graphiteLight,
        duration: duration,
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(_toneIcon(tone), color: color, size: 20),
              const SizedBox(width: CDRSpacingTokens.md),
              Expanded(
                child: Text(
                  message,
                  style: CDRTypographyTokens.bodySmall.copyWith(
                    color: CDRColorTokens.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                // Algumas cores semânticas não atingem AA em texto pequeno
                // sobre Grafite elevado. O ícone preserva o tom da mensagem.
                textColor: CDRColorTokens.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> success(
    BuildContext context,
    String message,
  ) =>
      show(context, message: message, tone: CDRSnackbarTone.success);

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(
        context,
        message: message,
        tone: CDRSnackbarTone.error,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> warning(
    BuildContext context,
    String message,
  ) =>
      show(context, message: message, tone: CDRSnackbarTone.warning);

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> info(
    BuildContext context,
    String message,
  ) =>
      show(context, message: message, tone: CDRSnackbarTone.info);
}

Color _toneColor(CDRSnackbarTone tone) => switch (tone) {
      CDRSnackbarTone.success => CDRColorTokens.success,
      CDRSnackbarTone.warning => CDRColorTokens.warning,
      CDRSnackbarTone.error => CDRColorTokens.error,
      CDRSnackbarTone.info => CDRColorTokens.info,
      CDRSnackbarTone.neutral => CDRColorTokens.brandYellow,
    };

IconData _toneIcon(CDRSnackbarTone tone) => switch (tone) {
      CDRSnackbarTone.success => Icons.check_circle_outline_rounded,
      CDRSnackbarTone.warning => Icons.warning_amber_rounded,
      CDRSnackbarTone.error => Icons.error_outline_rounded,
      CDRSnackbarTone.info => Icons.info_outline_rounded,
      CDRSnackbarTone.neutral => Icons.notifications_none_rounded,
    };
