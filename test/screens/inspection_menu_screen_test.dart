import 'package:appmobile/models/checkin_step2_model.dart';
import 'package:appmobile/models/inspection_session_model.dart';
import 'package:appmobile/repositories/fake_job_repository.dart';
import 'package:appmobile/screens/inspection_menu_screen.dart';
import 'package:appmobile/screens/overlay_camera_screen.dart';
import 'package:appmobile/services/inspection_flow_coordinator.dart';
import 'package:appmobile/services/inspection_local_storage_service.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:appmobile/state/inspection_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeInspectionFlowCoordinator extends InspectionFlowCoordinator {
  int reviewOpenCount = 0;
  String? lastReviewTipoImovel;
  int cameraFlowOpenCount = 0;

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
  Future<OverlayCameraCaptureResult?> openOverlayCamera(
    BuildContext context, {
    required String title,
    required String tipoImovel,
    required String subtipoImovel,
    bool singleCaptureMode = false,
    String? preselectedMacroLocal,
    String? initialAmbiente,
    String? initialElemento,
    required bool cameFromCheckinStep1,
  }) async {
    return null;
  }

  @override
  void openInspectionReview(
    BuildContext context, {
    List<OverlayCameraCaptureResult> captures =
        const <OverlayCameraCaptureResult>[],
    required String tipoImovel,
    bool cameFromCheckinStep1 = false,
  }) {
    reviewOpenCount += 1;
    lastReviewTipoImovel = tipoImovel;
  }

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
  void restoreCheckinStep2RecoveryFlow(
    BuildContext context, {
    required String tipoImovel,
    CheckinStep2Model? initialData,
    ValueChanged<CheckinStep2Model>? onContinue,
  }) {}

  @override
  void openCameraFlow(BuildContext context) {
    cameraFlowOpenCount += 1;
  }
}

class _MemoryInspectionLocalStorageService
    extends InspectionLocalStorageService {
  InspectionSession? activeSession;

  @override
  Future<InspectionSession?> loadActiveSession() async => activeSession;

  @override
  Future<void> saveActiveSession(InspectionSession session) async {
    activeSession = session;
  }

  @override
  Future<void> clearActiveSession() async {
    activeSession = null;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('InspectionMenuScreen delegates review actions to coordinator', (
    tester,
  ) async {
    final flowCoordinator = _FakeInspectionFlowCoordinator();
    final inspectionState = InspectionState(
      localStorageService: _MemoryInspectionLocalStorageService(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(
            value: AppState(FakeJobRepository()),
          ),
          ChangeNotifierProvider<InspectionState>.value(
            value: inspectionState,
          ),
        ],
        child: MaterialApp(
          home: InspectionMenuScreen(flowCoordinator: flowCoordinator),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await inspectionState.startMockInspection(
      tipoImovel: 'Urbano',
      subtipoImovel: 'Apartamento',
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Revisão final'));
    await tester.pump();

    expect(flowCoordinator.reviewOpenCount, 1);
    expect(flowCoordinator.lastReviewTipoImovel, 'Urbano • Apartamento');

    final reviewFab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    reviewFab.onPressed!.call();
    await tester.pump();

    expect(flowCoordinator.reviewOpenCount, 2);
    expect(flowCoordinator.lastReviewTipoImovel, 'Urbano • Apartamento');
  });

  testWidgets('InspectionMenuScreen delegates environment card open to coordinator', (
    tester,
  ) async {
    final flowCoordinator = _FakeInspectionFlowCoordinator();
    final inspectionState = InspectionState(
      localStorageService: _MemoryInspectionLocalStorageService(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(
            value: AppState(FakeJobRepository()),
          ),
          ChangeNotifierProvider<InspectionState>.value(
            value: inspectionState,
          ),
        ],
        child: MaterialApp(
          home: InspectionMenuScreen(flowCoordinator: flowCoordinator),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await inspectionState.startMockInspection(
      tipoImovel: 'Urbano',
      subtipoImovel: 'Apartamento',
    );
    await tester.pump();

    final salaCard = tester.widget<InkWell>(
      find.ancestor(of: find.text('Sala'), matching: find.byType(InkWell)).first,
    );
    salaCard.onTap!.call();
    await tester.pump();

    expect(flowCoordinator.cameraFlowOpenCount, 1);
  });
}
