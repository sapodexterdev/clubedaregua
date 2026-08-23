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
      _NavItem(Icons.search_rounded, 'Descobrir'),
      _NavItem(Icons.favorite_border_rounded, 'Favoritos'),
      _NavItem(Icons.calendar_month_outlined, 'Agenda'),
      _NavItem(Icons.person_outline_rounded, 'Perfil'),
    ];
    final captionHeight = MediaQuery.textScalerOf(context).scale(
          CDRTypographyTokens.caption.fontSize!,
        ) *
        CDRTypographyTokens.caption.height!;
    final contentHeight = 44 + captionHeight;
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
                            color:
                                selected ? AppColors.orange : AppColors.muted,
                            size: 24,
                          ),
                          const SizedBox(height: CDRSpacingTokens.xs),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CDRTypographyTokens.caption.copyWith(
                              color:
                                  selected ? AppColors.orange : AppColors.muted,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w600,
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
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
