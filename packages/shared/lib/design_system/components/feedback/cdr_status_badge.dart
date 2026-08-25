import 'package:flutter/material.dart';

import '../../tokens/cdr_design_tokens.dart';

enum CDRStatusTone { neutral, success, warning, error, info, brand }

class CDRStatusBadge extends StatelessWidget {
  const CDRStatusBadge({
    super.key,
    required this.label,
    this.tone = CDRStatusTone.neutral,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final CDRStatusTone tone;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(tone);
    return Semantics(
      container: true,
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CDRSpacingTokens.md,
            vertical: CDRSpacingTokens.sm,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(CDRRadiusTokens.pill),
            border: Border.all(color: color.withOpacity(.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 16),
                const SizedBox(width: CDRSpacingTokens.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CDRTypographyTokens.caption.copyWith(
                    // A cor semântica permanece no ícone, borda e fundo. Texto
                    // branco garante contraste AA também para o tom de erro.
                    color: CDRColorTokens.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CDRStatusChip extends CDRStatusBadge {
  const CDRStatusChip({
    super.key,
    required super.label,
    super.tone,
    super.icon,
    super.semanticLabel,
  });
}

Color _toneColor(CDRStatusTone tone) => switch (tone) {
      CDRStatusTone.neutral => CDRColorTokens.gray,
      CDRStatusTone.success => CDRColorTokens.success,
      CDRStatusTone.warning => CDRColorTokens.warning,
      CDRStatusTone.error => CDRColorTokens.error,
      CDRStatusTone.info => CDRColorTokens.info,
      CDRStatusTone.brand => CDRColorTokens.brandYellow,
    };
