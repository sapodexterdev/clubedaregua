import 'package:flutter/material.dart';

import '../models/service_item.dart';
import '../theme/app_colors.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final ServiceItem service;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange.withOpacity(.09)
              : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.orange : AppColors.stroke,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.orange.withOpacity(.16)
                    : AppColors.elevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.content_cut_rounded,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${service.durationMinutes} min',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'R\$ ${service.price.toStringAsFixed(0)}',
              style: TextStyle(
                color: isSelected ? AppColors.orange : AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
