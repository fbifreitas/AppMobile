import 'package:flutter/material.dart';

import '../../branding/brand_provider.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';

class OperationalHubCard extends StatelessWidget {
  const OperationalHubCard({
    super.key,
    required this.onOpen,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final tokens = BrandProvider.configOf(context).tokens;
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tokens.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.dashboard_customize_outlined,
              color: tokens.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.tr('Centrais integradas', 'Integrated centers'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.tr(
                    'Acesse fluxo, operação, IA, qualidade e produção em um único ponto.',
                    'Access flow, operations, AI, quality, and production in one place.',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: OutlinedButton(
              onPressed: onOpen,
              child: Text(strings.tr('ABRIR', 'OPEN')),
            ),
          ),
        ],
      ),
    );
  }
}
