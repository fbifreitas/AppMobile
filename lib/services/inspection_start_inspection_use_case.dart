import 'package:flutter/material.dart';

import '../models/job.dart';
import '../models/smart_execution_plan.dart';
import '../services/inspection_flow_coordinator.dart';
import '../services/inspection_recovery_navigation_service.dart';
import '../services/smart_execution_plan_service.dart';
import '../state/app_state.dart';

class InspectionStartInspectionUseCase {
  InspectionStartInspectionUseCase({
    InspectionRecoveryNavigationService? recoveryNavigationService,
    SmartExecutionPlanService? smartExecutionPlanService,
  }) : recoveryNavigationService =
           recoveryNavigationService ??
           InspectionRecoveryNavigationService.instance,
       smartExecutionPlanService =
           smartExecutionPlanService ?? const SmartExecutionPlanService();

  static final InspectionStartInspectionUseCase instance =
      InspectionStartInspectionUseCase();

  final InspectionRecoveryNavigationService recoveryNavigationService;
  final SmartExecutionPlanService smartExecutionPlanService;

  Future<void> execute(
    BuildContext context, {
    required AppState appState,
    required Job job,
    required InspectionFlowCoordinator flowCoordinator,
  }) async {
    final isRecovery = appState.hasRecoverableInspectionForJob(job.id);
    final latestExecutionPlan = await _loadLatestExecutionPlan(job.id);
    if (latestExecutionPlan != null) {
      job.smartExecutionPlan = latestExecutionPlan;
      job.tipoImovel = latestExecutionPlan.initialAssetType ?? job.tipoImovel;
      job.subtipoImovel =
          latestExecutionPlan.initialAssetSubtype ?? job.subtipoImovel;
      job.latitude = latestExecutionPlan.propertyLatitude ?? job.latitude;
      job.longitude = latestExecutionPlan.propertyLongitude ?? job.longitude;
    }

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

  Future<SmartExecutionPlan?> _loadLatestExecutionPlan(String jobId) async {
    try {
      return await smartExecutionPlanService.fetchForJob(jobId);
    } catch (_) {
      return null;
    }
  }
}
