import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/inspection_flow_coordinator.dart';
import '../services/inspection_recovery_navigation_service.dart';
import '../state/app_state.dart';

class InspectionStartInspectionUseCase {
  InspectionStartInspectionUseCase({
    InspectionRecoveryNavigationService? recoveryNavigationService,
  }) : recoveryNavigationService =
           recoveryNavigationService ??
           InspectionRecoveryNavigationService.instance;

  static final InspectionStartInspectionUseCase instance =
      InspectionStartInspectionUseCase();

  final InspectionRecoveryNavigationService recoveryNavigationService;

  Future<void> execute(
    BuildContext context, {
    required AppState appState,
    required Job job,
    required InspectionFlowCoordinator flowCoordinator,
  }) async {
    final isRecovery = appState.hasRecoverableInspectionForJob(job.id);

    appState.selecionarJob(job);
    if (!isRecovery) {
      await appState.beginInspectionRecovery(job);
    }

    if (!context.mounted) return;

    if (isRecovery) {
      final resumed = await recoveryNavigationService.resume(
        appState: appState,
        openCamera: (request) {
          return flowCoordinator.openOverlayCamera(context, request: request);
        },
        openReview: (tipoImovel, initialData, captures) {
          flowCoordinator.restoreReviewRecoveryFlow(
            context,
            tipoImovel: tipoImovel,
            initialData: initialData,
            onContinue: (model) async {
              await appState.persistStep2Draft(model.toMap());
            },
            captures: captures,
          );
        },
        openCheckinStep2: (tipoImovel, initialData) {
          flowCoordinator.restoreCheckinStep2RecoveryFlow(
            context,
            tipoImovel: tipoImovel,
            initialData: initialData,
            onContinue: (model) async {
              await appState.persistStep2Draft(model.toMap());
            },
          );
        },
        openCheckinStep1: () {
          flowCoordinator.openCheckin(context);
        },
      );
      if (resumed) {
        return;
      }
    }

    if (!context.mounted) return;
    flowCoordinator.openCheckin(context);
  }
}
