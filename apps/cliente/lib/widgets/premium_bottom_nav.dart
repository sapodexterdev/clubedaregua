import 'package:flutter/material.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

import '../theme/app_colors.dart';

class PremiumBottomNav extends StatelessWidget {
  const PremiumBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(
        Icons.search_rounded,
        'Descobrir',
        twoLineLabel: 'Desco\nbrir',
        threeLineLabel: 'Des\ncob\nrir',
      ),
      _NavItem(
        Icons.favorite_border_rounded,
        'Favoritos',
        twoLineLabel: 'Favori\ntos',
        threeLineLabel: 'Fav\nori\ntos',
      ),
      _NavItem(
        Icons.calendar_month_outlined,
        'Agenda',
        twoLineLabel: 'Agen\nda',
        threeLineLabel: 'Age\nnda',
      ),
      _NavItem(
        Icons.person_outline_rounded,
        'Perfil',
        twoLineLabel: 'Per\nfil',
        threeLineLabel: 'Per\nfil',
      ),
    ];
    final textScaler = MediaQuery.textScalerOf(context);
    final captionFontSize = CDRTypographyTokens.caption.fontSize!;
    final captionHeight =
        textScaler.scale(captionFontSize) * CDRTypographyTokens.caption.height!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / items.length;
        final captionStyle = CDRTypographyTokens.caption.copyWith(
          fontWeight: FontWeight.w700,
        );
        final captionLines = _requiredCaptionLines(
          items: items,
          itemWidth: itemWidth,
          style: captionStyle,
          textDirection: Directionality.of(context),
          textScaler: textScaler,
        );
        // Reserva ícone, espaçamento, texto e paddings com margem para o
        // arredondamento aplicado pelo layout em escalas fracionárias.
        final contentHeight = 46 + (captionHeight * captionLines);
        final navigationHeight = contentHeight > 72 ? contentHeight : 72.0;

        return SafeArea(
          top: false,
          child: Container(
            height: navigationHeight,
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.stroke)),
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = currentIndex == index;

                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: item.label,
                    child: InkWell(
                      onTap: () => onTap(index),
                      child: ExcludeSemantics(
                        child: AnimatedContainer(
                          duration: CDRDurationTokens.fast,
                          padding: const EdgeInsets.only(top: 9, bottom: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.orange.withOpacity(.08)
                                : AppColors.background.withOpacity(0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.icon,
                                color: selected
                                    ? AppColors.orange
                                    : AppColors.muted,
                                size: 24,
                              ),
                              const SizedBox(height: CDRSpacingTokens.xs),
                              Text(
                                item.labelForLines(captionLines),
                                maxLines: captionLines,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: CDRTypographyTokens.caption.copyWith(
                                  color: selected
                                      ? AppColors.orange
                                      : AppColors.muted,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem(
    this.icon,
    this.label, {
    required this.twoLineLabel,
    required this.threeLineLabel,
  });

  final IconData icon;
  final String label;
  final String twoLineLabel;
  final String threeLineLabel;

  String labelForLines(int lines) => switch (lines) {
        1 => label,
        2 => twoLineLabel,
        _ => threeLineLabel,
      };
}

int _requiredCaptionLines({
  required List<_NavItem> items,
  required double itemWidth,
  required TextStyle style,
  required TextDirection textDirection,
  required TextScaler textScaler,
}) {
  bool allLabelsFit(int lines) => items.every((item) {
        final painter = TextPainter(
          text: TextSpan(text: item.labelForLines(lines), style: style),
          maxLines: lines,
          textAlign: TextAlign.center,
          textDirection: textDirection,
          textScaler: textScaler,
        )..layout(maxWidth: itemWidth);
        return !painter.didExceedMaxLines;
      });

  if (allLabelsFit(1)) return 1;
  if (allLabelsFit(2)) return 2;
  return 3;
}
