import 'package:flutter/material.dart';

import '../../models/job.dart';
import '../../models/job_distance_info.dart';
import '../../services/job_distance_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';

typedef NavigateToJobCallback = Future<void> Function({
  required double? latitude,
  required double? longitude,
  required String address,
});

typedef StartInspectionCallback = void Function(Job job);

class JobsSection extends StatelessWidget {
  JobsSection({
    super.key,
    required this.appState,
    required this.onNavigateToJob,
    required this.onStartInspection,
    this.currentLatitude,
    this.currentLongitude,
    this.useDistanceMetrics = false,
    JobDistanceService? distanceService,
  }) : distanceService = distanceService ?? JobDistanceService();

  final AppState appState;
  final NavigateToJobCallback onNavigateToJob;
  final StartInspectionCallback onStartInspection;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool useDistanceMetrics;
  final JobDistanceService distanceService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MEUS JOBS DE HOJE',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        if (appState.isLoadingJobs)
          _buildInlineLoadingCard()
        else if (appState.jobsLoadError != null)
          _buildJobsLoadErrorCard(appState.jobsLoadError!)
        else if (appState.jobs.isEmpty)
          _buildEmptyJobsCard()
        else
          ...appState.jobs.map(
            (job) => _RichJobCard(
              job: job,
              distanceInfo: distanceService.buildDistanceInfo(
                job: job,
                currentLatitude: currentLatitude,
                currentLongitude: currentLongitude,
                useDistanceMetrics: useDistanceMetrics,
              ),
              onNavigateToJob: () {
                return onNavigateToJob(
                  latitude: job.latitude,
                  longitude: job.longitude,
                  address: job.endereco,
                );
              },
              onStartInspection: () {
                onStartInspection(job);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildInlineLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Carregando jobs...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsLoadErrorCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Não foi possível carregar as vistorias.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyJobsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'Nenhuma vistoria disponível no momento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RichJobCard extends StatelessWidget {
  const _RichJobCard({
    required this.job,
    required this.distanceInfo,
    required this.onNavigateToJob,
    required this.onStartInspection,
  });

  final Job job;
  final JobDistanceInfo distanceInfo;
  final Future<void> Function() onNavigateToJob;
  final VoidCallback onStartInspection;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'EM ANDAMENTO',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            job.titulo,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            job.endereco,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            job.nomeCliente,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _JobTag(
                bg: AppColors.primaryLight,
                fg: AppColors.primary,
                text: distanceInfo.label,
              ),
              _JobTag(
                bg: distanceInfo.withinRange
                    ? Colors.green.withValues(alpha: 0.12)
                    : AppColors.warningLight,
                fg: distanceInfo.withinRange
                    ? Colors.green.shade800
                    : AppColors.warning,
                text: distanceInfo.rangeLabel,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await onNavigateToJob();
                  },
                  child: const Text(
                    'COMO CHEGAR',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onStartInspection,
                  child: const Text(
                    'INICIAR VISTORIA',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobTag extends StatelessWidget {
  const _JobTag({
    required this.bg,
    required this.fg,
    required this.text,
  });

  final Color bg;
  final Color fg;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
        ),
      ),
    );
  }
}
