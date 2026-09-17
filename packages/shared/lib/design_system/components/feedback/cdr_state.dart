import 'package:flutter/material.dart';

import '../../tokens/cdr_design_tokens.dart';
import '../buttons/cdr_button.dart';

enum CDRStatePanelLayout { centered, inline }

class CDREmptyState extends StatelessWidget {
  const CDREmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => CDRStatePanel(
        icon: icon,
        iconColor: CDRColorTokens.gray,
        title: title,
        message: message,
        action: actionLabel != null && onAction != null
            ? CDRButton.outlined(
                label: actionLabel!,
                onPressed: onAction,
                isExpanded: false,
              )
            : null,
      );
}

class CDRErrorState extends StatelessWidget {
  const CDRErrorState({
    super.key,
    this.title = 'Não foi possível carregar',
    required this.message,
    this.icon = Icons.cloud_off_outlined,
    this.retryLabel = 'Tentar novamente',
    this.onRetry,
  });

  final String title;
  final String message;
  final IconData icon;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => CDRStatePanel(
        icon: icon,
        iconColor: CDRColorTokens.error,
        title: title,
        message: message,
        liveRegion: true,
        action: onRetry == null
            ? null
            : CDRButton.primary(
                label: retryLabel,
                onPressed: onRetry,
                isExpanded: false,
              ),
      );
}

class CDROfflineState extends StatelessWidget {
  const CDROfflineState({
    super.key,
    this.title = 'Você está sem conexão',
    this.message = 'Conecte-se à internet e tente novamente.',
    this.retryLabel = 'Tentar novamente',
    this.onRetry,
    this.layout = CDRStatePanelLayout.centered,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final CDRStatePanelLayout layout;

  @override
  Widget build(BuildContext context) => CDRStatePanel(
        icon: Icons.wifi_off_rounded,
        iconColor: CDRColorTokens.warning,
        title: title,
        message: message,
        layout: layout,
        liveRegion: true,
        action: onRetry == null
            ? null
            : CDRButton.primary(
                label: retryLabel,
                onPressed: onRetry,
                isExpanded: false,
              ),
      );
}

class CDRStatePanel extends StatelessWidget {
  const CDRStatePanel({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.action,
    this.liveRegion = false,
    this.layout = CDRStatePanelLayout.centered,
    this.backgroundColor = Colors.transparent,
    this.borderColor = Colors.transparent,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;
  final bool liveRegion;
  final CDRStatePanelLayout layout;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final content = layout == CDRStatePanelLayout.inline
        ? _inlineContent(context)
        : _centeredContent(context);
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(CDRRadiusTokens.medium),
          border: Border.all(color: borderColor),
        ),
        child: content,
      ),
    );
  }

  Widget _centeredContent(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(CDRSpacingTokens.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 40),
                const SizedBox(height: CDRSpacingTokens.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: CDRSpacingTokens.sm),
                _message(context, TextAlign.center),
                if (action != null) ...[
                  const SizedBox(height: CDRSpacingTokens.xl),
                  action!,
                ],
              ],
            ),
          ),
        ),
      );

  Widget _inlineContent(BuildContext context) => Padding(
        padding: const EdgeInsets.all(CDRSpacingTokens.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: CDRSpacingTokens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: CDRSpacingTokens.xs),
                  _message(context, TextAlign.start),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: CDRSpacingTokens.md),
              action!,
            ],
          ],
        ),
      );

  Widget _message(BuildContext context, TextAlign textAlign) => Text(
        message,
        textAlign: textAlign,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CDRColorTokens.gray,
            ),
      );
}
