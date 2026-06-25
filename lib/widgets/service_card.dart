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
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange : AppColors.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.content_cut,
                color: isSelected ? Colors.white : AppColors.orange,
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
                      color: isSelected ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${service.durationMinutes} min',
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'R\$ ${service.price.toStringAsFixed(0)}',
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
