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
      Icons.home_rounded,
      Icons.calendar_month_rounded,
      Icons.notifications_rounded,
      Icons.person_rounded,
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            final selected = currentIndex == index;
            return IconButton(
              onPressed: () => onTap(index),
              icon: Icon(icons[index]),
              color: selected ? AppColors.orange : Colors.white54,
              tooltip: 'Aba ${index + 1}',
            );
          }),
        ),
      ),
    );
  }
}
