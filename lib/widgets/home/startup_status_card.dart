import 'package:flutter/material.dart';

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
          const Text(
            'Status do startup',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'isLoadingJobs: $isLoadingJobs',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'jobs carregados: $jobsCount',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'jobsLoadError: ${jobsLoadError ?? "nenhum"}',
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
