import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TimeSelector extends StatelessWidget {
  const TimeSelector({
    required this.times,
    required this.selectedTime,
    required this.onSelected,
    super.key,
  });

  final List<String> times;
  final String selectedTime;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: times.map((time) {
        final selected = time == selectedTime;
        return ChoiceChip(
          label: Text(time),
          selected: selected,
          onSelected: (_) => onSelected(time),
          selectedColor: AppColors.orange,
          backgroundColor: AppColors.card,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.text,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide.none,
          ),
        );
      }).toList(),
    );
  }
}
