import 'package:flutter/material.dart';

import '../../branding/brand_provider.dart';
import '../../branding/brand_tokens.dart';
import '../../branding/resolved_brand_config.dart';
import '../../models/job.dart';
import '../../models/job_status.dart';
import '../../services/location_service.dart';
import '../../state/app_state.dart';

typedef NavigateToJobCallback =
    Future Function({
      required double? latitude,
      required double? longitude,
      required String address,
    });

typedef StartInspectionCallback = Future<void> Function(Job job);

class JobsSection extends StatelessWidget {
  const JobsSection({
    super.key,
    required this.appState,
    required this.onNavigateToJob,
    required this.onStartInspection,
    this.currentLatitude,
    this.currentLongitude,
    this.useDistanceMetrics = false,
    this.sectionTitle,
    this.geofenceRequired = true,
    this.startLabel,
    this.resumeLabel,
    this.startBlockedLabel,
    this.navigateLabel,
    this.withinRangeLabel,
    this.outOfRangeLabel,
  });

  final AppState appState;
  final NavigateToJobCallback onNavigateToJob;
  final StartInspectionCallback onStartInspection;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool useDistanceMetrics;

  /// Section heading. Falls back to 'MEUS JOBS DE HOJE' when null.
  /// Callers pass: config.copyText('jobs_section_title', defaultValue: 'MEUS JOBS DE HOJE')
  final String? sectionTitle;

  /// When false (Compass / corporate mode), geofence distance UI is hidden
  /// and the start button is always enabled regardless of radius.
  final bool geofenceRequired;

  /// Button label overrides resolved from brand copy.
  /// Falls back to canonical Portuguese when null.
  final String? startLabel;
  final String? resumeLabel;
  final String? startBlockedLabel;
  final String? navigateLabel;
  final String? withinRangeLabel;
  final String? outOfRangeLabel;

  @override
  Widget build(BuildContext context) {
    final config = BrandProvider.configOf(context);
    final tokens = config.tokens;
    final resolvedTitle =
        sectionTitle?.isNotEmpty == true
            ? sectionTitle!
            : config.copyText('jobs_section_title', defaultValue: 'MEUS JOBS DE HOJE');

    final loadingLabel = config.copyText('job_loading_label', defaultValue: 'Carregando jobs...');
    final errorTitle = config.copyText('job_error_title', defaultValue: 'Não foi possível carregar as vistorias.');
    final emptyLabel = config.copyText('job_empty_label', defaultValue: 'Nenhuma vistoria disponível no momento.');

    final activeJobs =
        appState.jobs
            .where((job) => job.status != JobStatus.finalizado)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          resolvedTitle,
          style: TextStyle(
            color: BrandTokens.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        if (appState.isLoadingJobs)
          _buildInlineLoadingCard(loadingLabel)
        else ...[
          if (appState.jobsLoadError != null)
            _buildJobsLoadErrorCard(appState.jobsLoadError!, errorTitle),
          if (activeJobs.isEmpty)
            _buildEmptyJobsCard(emptyLabel)
          else
            ...activeJobs.map(
              (job) => _RichJobCard(
                appState: appState,
                job: job,
                tokens: tokens,
                currentLatitude: currentLatitude,
                currentLongitude: currentLongitude,
                useDistanceMetrics: useDistanceMetrics,
                geofenceRequired: geofenceRequired,
                startLabel: startLabel,
                resumeLabel: resumeLabel,
                startBlockedLabel: startBlockedLabel,
                navigateLabel: navigateLabel,
                withinRangeLabel: withinRangeLabel,
                outOfRangeLabel: outOfRangeLabel,
                onNavigateToJob: () {
                  return onNavigateToJob(
                    latitude: job.latitude,
                    longitude: job.longitude,
                    address: job.endereco,
                  );
                },
                onStartInspection: () async {
                  await onStartInspection(job);
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildInlineLoadingCard(String loadingLabel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandTokens.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loadingLabel,
              style: const TextStyle(color: BrandTokens.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsLoadErrorCard(String message, String errorTitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            errorTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: BrandTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: BrandTokens.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyJobsCard(String emptyLabel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BrandTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandTokens.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 40,
            color: BrandTokens.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            emptyLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: BrandTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RichJobCard extends StatelessWidget {
  const _RichJobCard({
    required this.appState,
    required this.job,
    required this.tokens,
    required this.onNavigateToJob,
    required this.onStartInspection,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.useDistanceMetrics,
    required this.geofenceRequired,
    this.startLabel,
    this.resumeLabel,
    this.startBlockedLabel,
    this.navigateLabel,
    this.withinRangeLabel,
    this.outOfRangeLabel,
  });

  final AppState appState;
  final Job job;
  final BrandTokens tokens;
  final Future Function() onNavigateToJob;
  final Future<void> Function() onStartInspection;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool useDistanceMetrics;

  /// When false, geofence distance UI is hidden and the start button is always
  /// enabled (Compass / corporate mode doesn't enforce proximity).
  final bool geofenceRequired;

  final String? startLabel;
  final String? resumeLabel;
  final String? startBlockedLabel;
  final String? navigateLabel;
  final String? withinRangeLabel;
  final String? outOfRangeLabel;

  @override
  Widget build(BuildContext context) {
    final config = BrandProvider.configOf(context);
    final devHint = config.copyText('job_dev_mode_hint_label', defaultValue: 'Modo desenvolvedor ativo: fluxo liberado para teste fora do raio.');
    final devStartLabel = config.copyText('job_dev_mode_start_label', defaultValue: 'INICIAR (DEV)');
    final distanceInfo = _buildDistanceInfo(config);
    final canStart =
        !geofenceRequired ||
        appState.canStartInspection(
          job: job,
          currentLatitude: currentLatitude,
          currentLongitude: currentLongitude,
        );
    final showDevStart =
        geofenceRequired &&
        appState.shouldShowDevStart(
          job: job,
          currentLatitude: currentLatitude,
          currentLongitude: currentLongitude,
        );
    final radiusMeters = appState.resolveInspectionRadiusMeters(job);
    final isRecoverable = appState.hasRecoverableInspectionForJob(job.id);
    final recoveryStageLabel = appState.recoveryStageLabelForJob(job.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrandTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecoverable ? tokens.primary : BrandTokens.border,
          width: isRecoverable ? 1.5 : 1,
        ),
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
                decoration: BoxDecoration(
                  color:
                      isRecoverable ? BrandTokens.warning : tokens.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isRecoverable
                    ? config.copyText('job_status_recoverable_label', defaultValue: 'EM RECUPERAÇÃO')
                    : config.copyText('job_status_active_label', defaultValue: 'EM ANDAMENTO'),
                style: TextStyle(
                  color:
                      isRecoverable ? BrandTokens.warning : tokens.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 6),
              _JobTag(
                bg: BrandTokens.surface,
                fg: BrandTokens.textSecondary,
                text: 'JOB #${job.id}',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            job.titulo,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: BrandTokens.textPrimary,
            ),
          ),
          if (_hasExternalReferences) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (_normalizedExternalId != null)
                  _JobTag(
                    bg: BrandTokens.surface,
                    fg: BrandTokens.textSecondary,
                    text: 'ID externo: $_normalizedExternalId',
                  ),
                if (_normalizedProtocol != null)
                  _JobTag(
                    bg: BrandTokens.surface,
                    fg: BrandTokens.textSecondary,
                    text: 'Protocolo: $_normalizedProtocol',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 5),
          Text(
            job.endereco,
            style: const TextStyle(
              color: BrandTokens.textSecondary,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            job.nomeCliente,
            style: const TextStyle(
              color: BrandTokens.textSecondary,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 8),
          if (geofenceRequired)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _JobTag(
                  bg: tokens.primaryLight,
                  fg: tokens.primary,
                  text: distanceInfo.label,
                ),
                _JobTag(
                  bg:
                      distanceInfo.withinRange
                          ? Colors.green.withValues(alpha: 0.12)
                          : BrandTokens.warningLight,
                  fg:
                      distanceInfo.withinRange
                          ? Colors.green.shade800
                          : BrandTokens.warning,
                  text: distanceInfo.rangeLabel,
                ),
                _JobTag(
                  bg: BrandTokens.surface,
                  fg: BrandTokens.textSecondary,
                  text: '${config.copyText('job_geofence_radius_prefix', defaultValue: 'Raio:')} ${radiusMeters.toStringAsFixed(0)}m',
                ),
              ],
            ),
          const SizedBox(height: 8),
          if (isRecoverable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BrandTokens.warningLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${config.copyText('job_recovery_warning_prefix', defaultValue: 'Vistoria em andamento interrompida. Última etapa salva:')} $recoveryStageLabel.',
                style: const TextStyle(
                  color: BrandTokens.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (geofenceRequired && !canStart && !showDevStart)
            Text(
              startBlockedLabel ??
                  'Fora do raio de vistoria para ${job.tipoImovel ?? 'tipo não informado'}.',
              style: const TextStyle(
                color: BrandTokens.warning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (showDevStart)
            Text(
              devHint,
              style: TextStyle(
                color: tokens.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await onNavigateToJob();
                  },
                  child: Text(
                    navigateLabel ?? 'COMO CHEGAR',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      (canStart || showDevStart)
                          ? () async {
                            await onStartInspection();
                          }
                          : null,
                  child: Text(
                    isRecoverable
                        ? (resumeLabel ?? 'RETOMAR VISTORIA')
                        : showDevStart
                        ? devStartLabel
                        : (startLabel ?? 'INICIAR VISTORIA'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _DistanceInfo _buildDistanceInfo(ResolvedBrandConfig config) {
    final pendingLabel = config.copyText('job_location_pending_label', defaultValue: 'Localização pendente');
    final noCalcLabel = config.copyText('job_no_calculation_label', defaultValue: 'Sem cálculo');
    final onSiteLabel = config.copyText('job_on_site_label', defaultValue: 'Você está no local');

    if (!useDistanceMetrics ||
        currentLatitude == null ||
        currentLongitude == null ||
        job.latitude == null ||
        job.longitude == null) {
      return _DistanceInfo(
        label: pendingLabel,
        rangeLabel: noCalcLabel,
        withinRange: false,
      );
    }

    final distanceMeters = LocationService().calcularDistancia(
      lat1: currentLatitude!,
      lon1: currentLongitude!,
      lat2: job.latitude!,
      lon2: job.longitude!,
    );

    final withinRange = appState.inspectionRadiusService.isWithinRadius(
      distanceMeters: distanceMeters,
      tipoImovel: job.tipoImovel,
      subtipoImovel: job.subtipoImovel,
    );

    final withinLabel = withinRangeLabel ?? 'Dentro do raio';
    final outsideLabel = outOfRangeLabel ?? 'Fora do raio';

    if (distanceMeters <= 80) {
      return _DistanceInfo(
        label: onSiteLabel,
        rangeLabel: withinLabel,
        withinRange: true,
      );
    }

    if (distanceMeters < 1000) {
      return _DistanceInfo(
        label: '${distanceMeters.toStringAsFixed(0)} m de distância',
        rangeLabel: withinRange ? withinLabel : outsideLabel,
        withinRange: withinRange,
      );
    }

    return _DistanceInfo(
      label: '${(distanceMeters / 1000).toStringAsFixed(1)} km de distância',
      rangeLabel: withinRange ? withinLabel : outsideLabel,
      withinRange: withinRange,
    );
  }

  String? get _normalizedExternalId {
    final value = job.idExterno?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? get _normalizedProtocol {
    final value = job.protocoloExterno?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  bool get _hasExternalReferences =>
      _normalizedExternalId != null || _normalizedProtocol != null;
}

class _JobTag extends StatelessWidget {
  const _JobTag({required this.bg, required this.fg, required this.text});

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
