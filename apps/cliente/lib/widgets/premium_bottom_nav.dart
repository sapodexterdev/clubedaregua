import 'package:flutter/material.dart';

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

    return SafeArea(
      top: false,
      child: Container(
        height: 72,
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.only(top: 9, bottom: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.orange.withOpacity(.08)
                          : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          color: selected ? AppColors.orange : AppColors.muted,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                selected ? AppColors.orange : AppColors.muted,
                            fontSize: 12,
                            height: 1.2,
                            fontWeight:
                                selected ? FontWeight.w900 : FontWeight.w700,
                          ),
                        ),
                      ],
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
