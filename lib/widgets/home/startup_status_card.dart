import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';

class StartupStatusCard extends StatelessWidget {
  const StartupStatusCard({
    super.key,
    required this.isLoadingJobs,
    required this.jobsCount,
    required this.jobsLoadError,
  });

  final bool isLoadingJobs;
  final int jobsCount;
  final String? jobsLoadError;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.tr('Status do startup', 'Startup status'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.tr('isLoadingJobs: $isLoadingJobs', 'isLoadingJobs: $isLoadingJobs'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.tr('jobs carregados: $jobsCount', 'loaded jobs: $jobsCount'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.tr(
              'jobsLoadError: ${jobsLoadError ?? "nenhum"}',
              'jobsLoadError: ${jobsLoadError ?? "none"}',
            ),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
