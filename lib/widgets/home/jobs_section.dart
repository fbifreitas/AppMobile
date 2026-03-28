import 'package:flutter/material.dart';

import '../../services/location_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';

class JobsSection extends StatelessWidget {
  const JobsSection({
    super.key,
    required this.appState,
    required this.onNavigateToJob,
    required this.onStartInspection,
    this.currentLatitude,
    this.currentLongitude,
    this.useDistanceMetrics = false,
  });

  final AppState appState;
  final Future<void> Function({
    required double? latitude,
    required double? longitude,
    required String address,
  }) onNavigateToJob;
  final void Function(dynamic job) onStartInspection;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool useDistanceMetrics;

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
              currentLatitude: currentLatitude,
              currentLongitude: currentLongitude,
              useDistanceMetrics: useDistanceMetrics,
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
    required this.onNavigateToJob,
    required this.onStartInspection,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.useDistanceMetrics,
  });

  final dynamic job;
  final Future<void> Function() onNavigateToJob;
  final VoidCallback onStartInspection;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool useDistanceMetrics;

  @override
  Widget build(BuildContext context) {
    final distanceInfo = _buildDistanceInfo();

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

  _DistanceInfo _buildDistanceInfo() {
    if (!useDistanceMetrics ||
        currentLatitude == null ||
        currentLongitude == null ||
        job.latitude == null ||
        job.longitude == null) {
      return const _DistanceInfo(
        label: 'Localização pendente',
        rangeLabel: 'Sem cálculo',
        withinRange: false,
      );
    }

    final distanceMeters = LocationService().calcularDistancia(
      lat1: currentLatitude!,
      lon1: currentLongitude!,
      lat2: job.latitude!,
      lon2: job.longitude!,
    );

    if (distanceMeters <= 80) {
      return const _DistanceInfo(
        label: 'Você está no local',
        rangeLabel: 'Dentro do raio',
        withinRange: true,
      );
    }

    if (distanceMeters < 1000) {
      return _DistanceInfo(
        label: '${distanceMeters.toStringAsFixed(0)} m de distância',
        rangeLabel: distanceMeters <= 100 ? 'Dentro do raio' : 'Fora do raio',
        withinRange: distanceMeters <= 100,
      );
    }

    return _DistanceInfo(
      label: '${(distanceMeters / 1000).toStringAsFixed(1)} km de distância',
      rangeLabel: distanceMeters <= 100 ? 'Dentro do raio' : 'Fora do raio',
      withinRange: distanceMeters <= 100,
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

class _DistanceInfo {
  const _DistanceInfo({
    required this.label,
    required this.rangeLabel,
    required this.withinRange,
  });

  final String label;
  final String rangeLabel;
  final bool withinRange;
}
