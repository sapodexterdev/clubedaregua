import 'package:flutter/material.dart';
import 'package:clubedaregua_shared/clubedaregua_shared.dart';

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
    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${service.name}, ${service.durationMinutes} minutos, R\$ ${service.price.toStringAsFixed(0)}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
          child: AnimatedContainer(
            duration: CDRDurationTokens.fast,
            padding: const EdgeInsets.all(CDRSpacingTokens.lg),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.orange : AppColors.card,
              borderRadius: BorderRadius.circular(CDRRadiusTokens.large),
              border: Border.all(
                color: isSelected ? AppColors.orange : AppColors.stroke,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.onGold.withOpacity(.12)
                        : AppColors.elevated,
                    borderRadius: BorderRadius.circular(CDRRadiusTokens.medium),
                  ),
                  child: Icon(
                    Icons.content_cut_rounded,
                    color: isSelected ? AppColors.onGold : AppColors.orange,
                  ),
                ),
                const SizedBox(width: CDRSpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CDRTypographyTokens.label.copyWith(
                          color: isSelected ? AppColors.onGold : AppColors.text,
                        ),
                      ),
                      const SizedBox(height: CDRSpacingTokens.xs),
                      Text(
                        '${service.durationMinutes} min',
                        style: CDRTypographyTokens.bodySmall.copyWith(
                          color:
                              isSelected ? AppColors.onGold : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: CDRSpacingTokens.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${service.price.toStringAsFixed(0)}',
                      style: CDRTypographyTokens.label.copyWith(
                        color: isSelected ? AppColors.onGold : AppColors.text,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: CDRSpacingTokens.xs),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.onGold,
                        size: CDRSizeTokens.icon,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
