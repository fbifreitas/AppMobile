import 'package:appmobile/models/checkin_step2_model.dart';
import 'package:appmobile/config/checkin_step2_config.dart';
import 'package:appmobile/models/inspection_session_model.dart';
import 'package:appmobile/models/inspection_camera_flow_request.dart';
import 'package:appmobile/models/job.dart';
import 'package:appmobile/models/overlay_camera_capture_result.dart';
import 'package:appmobile/repositories/fake_job_repository.dart';
import 'package:appmobile/screens/inspection_menu_screen.dart';
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
    required InspectionCameraFlowRequest request,
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
          ChangeNotifierProvider<InspectionState>.value(value: inspectionState),
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

  testWidgets(
    'InspectionMenuScreen delegates environment card open to coordinator',
    (tester) async {
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
        find
            .ancestor(of: find.text('Sala'), matching: find.byType(InkWell))
            .first,
      );
      salaCard.onTap!.call();
      await tester.pump();

      expect(flowCoordinator.cameraFlowOpenCount, 1);
    },
  );

  testWidgets(
    'InspectionMenuScreen counts mandatory progress from persisted dynamic step2 config',
    (tester) async {
      final flowCoordinator = _FakeInspectionFlowCoordinator();
      final inspectionState = InspectionState(
        localStorageService: _MemoryInspectionLocalStorageService(),
      );
      final appState = AppState(FakeJobRepository());

      appState.selecionarJob(
        Job(
          id: 'job-1',
          titulo: 'Vistoria A',
          endereco: 'Rua A, 1',
          nomeCliente: 'Cliente A',
        ),
      );

      await appState.setInspectionRecoveryStage(
        stageKey: 'inspection_review',
        stageLabel: 'Revisão final',
        routeName: '/inspection_review',
        payload: {
          'step2Config': {
            'tituloTela': 'Etapa 2 dinâmica',
            'camposFotos': [
              {
                'id': 'sala_principal',
                'titulo': 'Sala principal',
                'cameraMacroLocal': 'Interna',
                'cameraAmbiente': 'Sala principal',
                'obrigatorio': true,
              },
            ],
          },
        },
      );

      final persistedStep2 =
          CheckinStep2Model.empty(TipoImovel.urbano)
              .setPhoto(
                fieldId: 'sala_principal',
                titulo: 'Sala principal',
                imagePath: '/tmp/sala.jpg',
                geoPoint: GeoPointData(
                  latitude: -23.0,
                  longitude: -46.0,
                  accuracy: 5,
                  capturedAt: DateTime(2026, 3, 30),
                ),
              )
              .toMap();

      await appState.persistStep2Draft(persistedStep2);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
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

      expect(find.textContaining('1 mínimas'), findsOneWidget);
    },
  );
}
