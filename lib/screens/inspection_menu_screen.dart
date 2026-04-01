import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/checkin_step2_config.dart';
import '../models/inspection_session_model.dart';
import '../services/checkin_dynamic_config_service.dart';
import '../services/inspection_flow_coordinator.dart';
import '../state/app_state.dart';
import '../state/inspection_state.dart';

class InspectionMenuScreen extends StatelessWidget {
  final InspectionFlowCoordinator flowCoordinator;

  const InspectionMenuScreen({
    super.key,
    this.flowCoordinator = const DefaultInspectionFlowCoordinator(),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, InspectionState>(
      builder: (context, appState, inspectionState, _) {
        if (inspectionState.isRestoring) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = inspectionState.session;

        if (session == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('VISTORIA')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton(
                  onPressed: () async {
                    await inspectionState.startMockInspection(
                      tipoImovel: 'Urbano',
                      subtipoImovel: 'Apartamento',
                    );
                  },
                  child: const Text('Iniciar Vistoria'),
                ),
              ),
            ),
          );
        }

        final percent = (session.progressPercent * 100).round();

        return Scaffold(
          appBar: AppBar(
            title: const Text('VISTORIA'),
            actions: [
              IconButton(
                tooltip: 'Revisão final',
                onPressed: () {
                  flowCoordinator.openInspectionReview(
                    context,
                    tipoImovel:
                        '${session.tipoImovel} • ${session.subtipoImovel}',
                  );
                },
                icon: const Icon(Icons.fact_check_outlined),
              ),
            ],
          ),
          body: Column(
            children: [
              _HeaderCard(
                tipoImovel: session.tipoImovel,
                subtipoImovel: session.subtipoImovel,
                percent: percent,
                totalFotos: session.totalCapturedPhotos,
                obrigatorias: _countCompletedMandatoryFields(
                  session: session,
                  inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
                  step2Payload: appState.step2Payload,
                ),
                gpsEnabled: session.gpsEnabled,
                syncStatus: session.syncStatus,
                lastSavedAt: session.lastSavedAt,
                onToggleGps: () {
                  inspectionState.setGpsEnabled(!session.gpsEnabled);
                },
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: session.ambientes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ambiente = session.ambientes[index];
                    return _EnvironmentCard(
                      ambiente: ambiente,
                      onOpen: () {
                        inspectionState.selectEnvironment(ambiente.ambienteId);
                        flowCoordinator.openCameraFlow(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              flowCoordinator.openInspectionReview(
                context,
                tipoImovel: '${session.tipoImovel} • ${session.subtipoImovel}',
              );
            },
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Revisar'),
          ),
        );
      },
    );
  }

  int _countCompletedMandatoryFields({
    required InspectionSession session,
    required Map<String, dynamic> inspectionRecoveryPayload,
    required Map<String, dynamic> step2Payload,
  }) {
    final tipo = TipoImovelExtension.fromString(session.tipoImovel.trim());
    return CheckinDynamicConfigService.instance.countCompletedMandatoryFields(
      tipo: tipo,
      inspectionRecoveryPayload: inspectionRecoveryPayload,
      step2Payload: step2Payload,
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String tipoImovel;
  final String subtipoImovel;
  final int percent;
  final int totalFotos;
  final int obrigatorias;
  final bool gpsEnabled;
  final InspectionSyncStatus syncStatus;
  final DateTime? lastSavedAt;
  final VoidCallback onToggleGps;

  const _HeaderCard({
    required this.tipoImovel,
    required this.subtipoImovel,
    required this.percent,
    required this.totalFotos,
    required this.obrigatorias,
    required this.gpsEnabled,
    required this.syncStatus,
    required this.lastSavedAt,
    required this.onToggleGps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syncLabel = switch (syncStatus) {
      InspectionSyncStatus.draft => 'Rascunho local',
      InspectionSyncStatus.pendingUpload => 'Pendente de envio',
      InspectionSyncStatus.synced => 'Sincronizado',
      InspectionSyncStatus.uploadFailed => 'Falha no envio',
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$tipoImovel • $subtipoImovel',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: percent / 100),
          const SizedBox(height: 8),
          Text(
            '$percent% concluído • $totalFotos fotos • $obrigatorias mínimas',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text('Status local: $syncLabel', style: theme.textTheme.bodyMedium),
          if (lastSavedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Último salvamento: $lastSavedAt',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                gpsEnabled ? Icons.location_on : Icons.location_off,
                color:
                    gpsEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  gpsEnabled ? 'GPS ativo' : 'GPS desligado',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              OutlinedButton(
                onPressed: onToggleGps,
                child: Text(gpsEnabled ? 'Desligar' : 'Ligar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnvironmentCard extends StatelessWidget {
  final InspectionEnvironmentProgress ambiente;
  final VoidCallback onOpen;

  const _EnvironmentCard({required this.ambiente, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _statusLabel(ambiente.status);

    return Semantics(
      button: true,
      label: 'Abrir ambiente ${ambiente.ambienteNome}',
      child: InkWell(
        key: ValueKey('inspection_environment_${ambiente.ambienteId}'),
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
            color: theme.colorScheme.surface,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(ambiente.ambienteNome.characters.first.toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ambiente.ambienteNome,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ambiente.totalFotos}/${ambiente.minFotos} foto(s) mínimas • $status',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (ambiente.suggestedAsMissingConfig) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ambiente não configurado',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(InspectionEnvironmentStatus status) {
    switch (status) {
      case InspectionEnvironmentStatus.pendente:
        return 'Pendente';
      case InspectionEnvironmentStatus.emAndamento:
        return 'Em andamento';
      case InspectionEnvironmentStatus.concluido:
        return 'Concluído';
      case InspectionEnvironmentStatus.incompleto:
        return 'Incompleto';
      case InspectionEnvironmentStatus.naoConfigurado:
        return 'Não configurado';
    }
  }
}
