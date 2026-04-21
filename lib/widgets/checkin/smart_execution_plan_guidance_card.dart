import 'package:flutter/material.dart';

import '../../services/smart_execution_plan_guidance_presenter.dart';
import '../../theme/app_colors.dart';

class SmartExecutionPlanGuidanceCard extends StatelessWidget {
  const SmartExecutionPlanGuidanceCard({
    super.key,
    required this.guidance,
  });

  final SmartExecutionPlanGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        guidance.requiresAttention ? AppColors.warning : AppColors.success;
    final backgroundColor =
        guidance.requiresAttention
            ? AppColors.warningLight
            : AppColors.successLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  guidance.title,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...guidance.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.circle, size: 8, color: accentColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
