import 'package:appmobile/models/job.dart';
import 'package:appmobile/models/inspection_session_model.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/services/inspection_flow_coordinator.dart';
import 'package:appmobile/screens/inspection_review_screen.dart';
import 'package:appmobile/screens/overlay_camera_screen.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:appmobile/config/checkin_step2_config.dart';
import 'package:appmobile/models/checkin_step2_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void Function(FlutterErrorDetails)? _originalFlutterErrorHandler;

class _ImmediateJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => <Job>[];
}

class _FakeInspectionFlowCoordinator extends InspectionFlowCoordinator {
  OverlayCameraCaptureResult? nextOverlayResult;
  int overlayOpenCount = 0;
  String? lastOverlayTitle;

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
    String? initialMaterial,
    String? initialEstado,
    required bool cameFromCheckinStep1,
  }) async {
    overlayOpenCount += 1;
    lastOverlayTitle = title;
    return nextOverlayResult;
  }

  @override
  void openInspectionReview(
    BuildContext context, {
    List<OverlayCameraCaptureResult> captures =
        const <OverlayCameraCaptureResult>[],
    required String tipoImovel,
    bool cameFromCheckinStep1 = false,
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
  void restoreCheckinStep2RecoveryFlow(
    BuildContext context, {
    required String tipoImovel,
    CheckinStep2Model? initialData,
    ValueChanged<CheckinStep2Model>? onContinue,
  }) {}

  @override
  void openCameraFlow(BuildContext context) {}
}

OverlayCameraCaptureResult _capture({
  required String filePath,
  required String ambiente,
  String? elemento,
  String? material,
  String? estado,
}) {
  return OverlayCameraCaptureResult(
    filePath: filePath,
    ambiente: ambiente,
    elemento: elemento,
    material: material,
    estado: estado,
    capturedAt: DateTime(2026, 1, 1),
    latitude: -23.0,
    longitude: -46.0,
    accuracy: 5,
  );
}

Future<void> _pumpReview(
  WidgetTester tester, {
  required List<OverlayCameraCaptureResult> captures,
  String tipoImovel = 'Urbano',
  Map<String, dynamic>? persistedStep2Payload,
  Map<String, dynamic>? persistedRecoveryPayload,
  InspectionFlowCoordinator flowCoordinator =
      const DefaultInspectionFlowCoordinator(),
}) async {
  tester.view.physicalSize = const Size(1440, 2560);
  tester.view.devicePixelRatio = 1.0;

  final appState = AppState(_ImmediateJobRepository());
  if (persistedStep2Payload != null) {
    appState.selecionarJob(
      Job(
        id: 'job-1',
        titulo: 'Vistoria A',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
      ),
    );
    await appState.persistStep2Draft(persistedStep2Payload);
  } else if (persistedRecoveryPayload != null) {
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
      payload: persistedRecoveryPayload,
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: InspectionReviewScreen(
          captures: captures,
          tipoImovel: tipoImovel,
          cameFromCheckinStep1: false,
          flowCoordinator: flowCoordinator,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});

    _originalFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final exceptionText = details.exceptionAsString();
      if (exceptionText.contains('A RenderFlex overflowed')) {
        return;
      }
      final handler = _originalFlutterErrorHandler;
      if (handler != null) {
        handler(details);
        return;
      }
      FlutterError.presentError(details);
    };
  });

  tearDown(() {
    FlutterError.onError = _originalFlutterErrorHandler;
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first
        .resetPhysicalSize();
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first
        .resetDevicePixelRatio();
  });

  testWidgets('shows review CTA without pending shortcut link', (tester) async {
    await _pumpReview(
      tester,
      captures: [_capture(filePath: '/tmp/a.jpg', ambiente: 'Cozinha')],
    );

    expect(find.text('FINALIZAR VISTORIA'), findsOneWidget);
    expect(find.text('Ir para principal pendência'), findsNothing);
  });

  testWidgets('consolidates pending content under one review section', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      captures: [
        _capture(
          filePath: '/tmp/a.jpg',
          ambiente: 'Cozinha',
          elemento: 'Piso',
          material: 'Cerâmica',
          estado: 'Bom',
        ),
      ],
    );

    expect(find.text('REVISÃO DE FOTOS'), findsOneWidget);
    expect(find.text('Fotos Obrigatórias Do Check-In'), findsOneWidget);
    expect(find.text('Fotos Capturadas'), findsOneWidget);
  });

  testWidgets('does not render optional voice commands section', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      captures: [_capture(filePath: '/tmp/a.jpg', ambiente: 'Cozinha')],
    );

    expect(find.text('Comandos por voz (opcional)'), findsNothing);
    expect(find.text('Comandos rápidos por voz'), findsNothing);
  });

  testWidgets('does not render old top grouping chips frame', (tester) async {
    await _pumpReview(
      tester,
      captures: [
        _capture(
          filePath: '/tmp/a.jpg',
          ambiente: 'Cozinha',
          elemento: 'Piso',
          material: 'Cerâmica',
          estado: 'Bom',
        ),
      ],
    );

    expect(find.textContaining('Fotos obrigatórias:'), findsNothing);
    expect(find.textContaining('Fotos capturadas:'), findsNothing);
    expect(find.textContaining('REVISÃO DE FOTOS'), findsOneWidget);
  });

  testWidgets('renders pending shortcut action in technical matrix', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      captures: [_capture(filePath: '/tmp/a.jpg', ambiente: 'Cozinha')],
    );

    expect(find.text('PENDÊNCIAS TÉCNICAS DA VISTORIA'), findsOneWidget);
    expect(find.text('Ir para pendência'), findsWidgets);
  });

  testWidgets(
    'keeps persisted mandatory check-in photos as fulfilled on review reopen',
    (tester) async {
      final geoPoint = GeoPointData(
        latitude: -23.0,
        longitude: -46.0,
        accuracy: 5,
        capturedAt: DateTime(2026, 3, 30),
      );

      final persistedStep2 =
          CheckinStep2Model.empty(TipoImovel.urbano)
              .setPhoto(
                fieldId: 'fachada',
                titulo: 'Fachada',
                imagePath: '/tmp/fachada.jpg',
                geoPoint: geoPoint,
              )
              .setPhoto(
                fieldId: 'logradouro',
                titulo: 'Logradouro',
                imagePath: '/tmp/logradouro.jpg',
                geoPoint: geoPoint,
              )
              .toMap();

      await _pumpReview(
        tester,
        captures: const [],
        tipoImovel: 'Urbano • Apartamento',
        persistedStep2Payload: persistedStep2,
      );

      expect(find.text('Fachada'), findsOneWidget);
      expect(find.text('Logradouro'), findsOneWidget);
      expect(find.text('Obrigatório atendido'), findsNWidgets(2));
      expect(find.text('Obrigatório — pendente de captura'), findsNWidgets(2));
      expect(find.text('Capturar'), findsNWidgets(2));
    },
  );

  testWidgets(
    'captures missing mandatory requirement through injected coordinator',
    (tester) async {
      final geoPoint = GeoPointData(
        latitude: -23.0,
        longitude: -46.0,
        accuracy: 5,
        capturedAt: DateTime(2026, 3, 30),
      );
      final persistedStep2 =
          CheckinStep2Model.empty(TipoImovel.urbano)
              .setPhoto(
                fieldId: 'fachada',
                titulo: 'Fachada',
                imagePath: '/tmp/fachada.jpg',
                geoPoint: geoPoint,
              )
              .setPhoto(
                fieldId: 'logradouro',
                titulo: 'Logradouro',
                imagePath: '/tmp/logradouro.jpg',
                geoPoint: geoPoint,
              )
              .toMap();
      final flowCoordinator =
          _FakeInspectionFlowCoordinator()
            ..nextOverlayResult = _capture(
              filePath: '/tmp/acesso.jpg',
              ambiente: 'Acesso ao imóvel',
              elemento: 'Portão',
            );

      await _pumpReview(
        tester,
        captures: const [],
        tipoImovel: 'Urbano • Apartamento',
        persistedStep2Payload: persistedStep2,
        flowCoordinator: flowCoordinator,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Capturar').first);
      await tester.pumpAndSettle();

      expect(flowCoordinator.overlayOpenCount, 1);
      expect(flowCoordinator.lastOverlayTitle, 'Acesso ao imóvel');
      expect(find.text('Obrigatório atendido'), findsNWidgets(2));
      expect(find.widgetWithText(FilledButton, 'Capturar'), findsOneWidget);
    },
  );

  testWidgets(
    'uses persisted dynamic step2 config to mark fulfilled mandatory fields',
    (tester) async {
      final geoPoint = GeoPointData(
        latitude: -23.0,
        longitude: -46.0,
        accuracy: 5,
        capturedAt: DateTime(2026, 3, 30),
      );

      final persistedStep2 =
          CheckinStep2Model.empty(TipoImovel.urbano)
              .setPhoto(
                fieldId: 'sala_principal',
                titulo: 'Sala principal',
                imagePath: '/tmp/sala.jpg',
                geoPoint: geoPoint,
              )
              .toMap();

      await _pumpReview(
        tester,
        captures: const [],
        tipoImovel: 'Urbano • Apartamento',
        persistedRecoveryPayload: {
          'step2': persistedStep2,
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

      expect(find.text('Sala principal'), findsOneWidget);
      expect(find.text('Obrigatório atendido'), findsOneWidget);
      expect(find.text('Obrigatório — pendente de captura'), findsNothing);
    },
  );

  testWidgets(
    'handles malformed persisted step2 payload and keeps mandatory pending indicator',
    (tester) async {
      await _pumpReview(
        tester,
        captures: const [],
        tipoImovel: 'Urbano • Apartamento',
        persistedRecoveryPayload: {
          'step2': {'fotos': 'invalid-structure'},
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

      expect(find.text('Fotos Obrigatórias Do Check-In'), findsOneWidget);
      expect(find.text('Sala principal'), findsOneWidget);
      expect(find.text('Obrigatório — pendente de captura'), findsOneWidget);
    },
  );

  testWidgets(
    'keeps reviewed classification after reopening review with new camera captures',
    (tester) async {
      final recoveryPayload = {
        'review': {
          'tipoImovel': 'Urbano • Apartamento',
          'captures': [
            _capture(
              filePath: '/tmp/classificada.jpg',
              ambiente: 'Cozinha',
            ).toMap(),
            _capture(filePath: '/tmp/nova.jpg', ambiente: 'Sala').toMap(),
          ],
          'capturesRevisadas': [
            {
              'filePath': '/tmp/classificada.jpg',
              'ambiente': 'Cozinha',
              'elemento': 'Piso',
              'material': 'Cerâmica',
              'estado': 'Bom',
              'isComplete': true,
            },
          ],
        },
      };

      await _pumpReview(
        tester,
        captures: [
          _capture(filePath: '/tmp/classificada.jpg', ambiente: 'Cozinha'),
          _capture(filePath: '/tmp/nova.jpg', ambiente: 'Sala'),
        ],
        tipoImovel: 'Urbano • Apartamento',
        persistedRecoveryPayload: recoveryPayload,
      );

      expect(find.text('Fotos Capturadas'), findsOneWidget);
      expect(
        find.textContaining('1 pendência(s) de classificação'),
        findsOneWidget,
      );
    },
  );
}
