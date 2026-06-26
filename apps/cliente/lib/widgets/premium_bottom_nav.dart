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
    const icons = [
      Icons.home_outlined,
      Icons.search_rounded,
      Icons.favorite_border_rounded,
      Icons.person_rounded,
    ];
    const labels = ['Início', 'Buscar', 'Favoritos', 'Perfil'];

    return SafeArea(
      top: false,
      child: Container(
        height: 82,
        margin: const EdgeInsets.fromLTRB(44, 0, 44, 16),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(42),
        ),
        child: Row(
          children: List.generate(icons.length, (index) {
            final selected = currentIndex == index;
            return Expanded(
              flex: selected ? 2 : 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(34),
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 64,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : const Color(0xFF232323),
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.orange : Colors.transparent,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: AppColors.orange)
                              : Border.all(color: Colors.white24),
                        ),
                        child: Icon(
                          icons[index],
                          color: selected ? Colors.white : Colors.white54,
                          size: 24,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 10),
                        Text(
                          labels[index],
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
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
