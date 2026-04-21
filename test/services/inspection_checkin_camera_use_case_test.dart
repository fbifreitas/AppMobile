import 'package:appmobile/models/checkin_step2_model.dart';
import 'package:appmobile/models/flow_selection.dart';
import 'package:appmobile/models/inspection_camera_flow_request.dart';
import 'package:appmobile/models/job.dart';
import 'package:appmobile/models/overlay_camera_capture_result.dart';
import 'package:appmobile/models/smart_execution_plan.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/services/inspection_checkin_camera_use_case.dart';
import 'package:appmobile/services/inspection_flow_coordinator.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ImmediateJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => <Job>[];
}

class _FakeInspectionFlowCoordinator extends InspectionFlowCoordinator {
  InspectionCameraFlowRequest? lastRequest;

  @override
  void openCameraFlow(BuildContext context) {}

  @override
  void openCheckin(BuildContext context, {bool silent = false}) {}

  @override
  void openCheckinStep2(
    BuildContext context, {
    required String tipoImovel,
    CheckinStep2Model? initialData,
    ValueChanged<CheckinStep2Model>? onContinue,
    bool silent = false,
  }) {}

  @override
  void openInspectionReview(
    BuildContext context, {
    List<OverlayCameraCaptureResult> captures =
        const <OverlayCameraCaptureResult>[],
    required String tipoImovel,
    bool cameFromCheckinStep1 = false,
  }) {}

  @override
  void restoreCheckinStep2RecoveryFlow(
    BuildContext context, {
    required String tipoImovel,
    CheckinStep2Model? initialData,
    ValueChanged<CheckinStep2Model>? onContinue,
  }) {}

  @override
  void restoreReviewRecoveryFlow(
    BuildContext context, {
    required String tipoImovel,
    CheckinStep2Model? initialData,
    ValueChanged<CheckinStep2Model>? onContinue,
    List<OverlayCameraCaptureResult> captures =
        const <OverlayCameraCaptureResult>[],
  }) {}

  @override
  Future<OverlayCameraCaptureResult?> openOverlayCamera(
    BuildContext context, {
    required InspectionCameraFlowRequest request,
  }) async {
    lastRequest = request;
    return null;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'openFromStep1 keeps the explicit checkin selection without plan hints',
    (tester) async {
      final appState = AppState(_ImmediateJobRepository());
      appState.selecionarJob(
        Job(
          id: 'job-smart-camera',
          titulo: 'Vistoria Smart',
          endereco: 'Rua Inteligente, 10',
        ),
      );
      appState.currentExecutionPlan = const SmartExecutionPlan(
        snapshotId: 9,
        caseId: 88,
        status: 'PUBLISHED',
        jobId: 'job-smart-camera',
        initialContext: 'Street',
        firstEnvironment: 'Front elevation',
        firstElement: 'Primary facade',
        firstMaterial: 'Concrete',
        firstCondition: 'Good',
      );

      final coordinator = _FakeInspectionFlowCoordinator();
      const useCase = InspectionCheckinCameraUseCase();

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      await useCase.openFromStep1(
        tester.element(find.byType(SizedBox)),
        flowCoordinator: coordinator,
        appState: appState,
        tipoImovel: 'Urbano',
        subtipoImovel: 'Apartamento',
        initialSelection: const FlowSelection(subjectContext: 'Rua'),
      );

      final request = coordinator.lastRequest;
      expect(request, isNotNull);
      expect(request!.selectionState.initialSuggestedSelection.subjectContext, 'Rua');
      expect(request.selectionState.initialSuggestedSelection.targetItem, isNull);
      expect(request.selectionState.initialSuggestedSelection.targetQualifier, isNull);
      expect(
        request.selectionState.initialSuggestedSelection.attributeText(
          'inspection.material',
        ),
        isNull,
      );
      expect(request.selectionState.initialSuggestedSelection.targetCondition, isNull);
    },
  );
}
