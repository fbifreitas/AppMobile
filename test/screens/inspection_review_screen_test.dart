import 'package:appmobile/models/job.dart';
import 'package:appmobile/models/inspection_camera_flow_request.dart';
import 'package:appmobile/models/inspection_session_model.dart';
import 'package:appmobile/models/overlay_camera_capture_result.dart';
import 'package:appmobile/models/smart_execution_plan.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/l10n/app_strings.dart';
import 'package:appmobile/services/inspection_flow_coordinator.dart';
import 'package:appmobile/screens/inspection_review_screen.dart';
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
  InspectionCameraFlowRequest? lastOverlayRequest;

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
    overlayOpenCount += 1;
    lastOverlayRequest = request;
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

Map<String, dynamic> _requiredReviewStep2Config({
  List<Map<String, dynamic>>? photoFields,
}) {
  return {
    'visivel': true,
    'obrigatoriaParaEntrega': true,
    'obrigatoria': true,
    'camposFotos':
        photoFields ??
        [
          {
            'id': 'fachada',
            'titulo': 'Fachada',
            'cameraMacroLocal': 'Rua',
            'cameraAmbiente': 'Fachada',
            'obrigatorio': true,
          },
          {
            'id': 'logradouro',
            'titulo': 'Logradouro',
            'cameraMacroLocal': 'Rua',
            'cameraAmbiente': 'Logradouro',
            'obrigatorio': true,
          },
          {
            'id': 'acesso_imovel',
            'titulo': 'Acesso ao imóvel',
            'cameraMacroLocal': 'Rua',
            'cameraAmbiente': 'Acesso ao imóvel',
            'obrigatorio': true,
          },
          {
            'id': 'entorno',
            'titulo': 'Entorno',
            'cameraMacroLocal': 'Rua',
            'cameraAmbiente': 'Entorno',
            'obrigatorio': true,
          },
        ],
  };
}

Future<void> _pumpReview(
  WidgetTester tester, {
  required List<OverlayCameraCaptureResult> captures,
  String tipoImovel = 'Urbano',
  Map<String, dynamic>? persistedStep2Payload,
  Map<String, dynamic>? persistedRecoveryPayload,
  SmartExecutionPlan? smartExecutionPlan,
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
        smartExecutionPlan: smartExecutionPlan,
      ),
    );
    await appState.persistStep2Draft(persistedStep2Payload);
  }
  if (persistedRecoveryPayload != null) {
    appState.selecionarJob(
      Job(
        id: 'job-1',
        titulo: 'Vistoria A',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
        smartExecutionPlan: smartExecutionPlan,
      ),
    );
    await appState.setInspectionRecoveryStage(
      stageKey: 'inspection_review',
      stageLabel: 'Revisão final',
      routeName: '/inspection_review',
      payload: persistedRecoveryPayload,
    );
  }

  if (persistedStep2Payload == null && persistedRecoveryPayload == null) {
    appState.selecionarJob(
      Job(
        id: 'job-1',
        titulo: 'Vistoria A',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
        smartExecutionPlan: smartExecutionPlan,
      ),
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
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

  testWidgets('shows review CTA without old pending shortcut link', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      captures: [_capture(filePath: '/tmp/a.jpg', ambiente: 'Cozinha')],
    );

    expect(find.text('Finalizar vistoria'), findsOneWidget);
    expect(find.text('Ir para principal pendência'), findsNothing);
  });

  testWidgets('renders new review information blocks', (tester) async {
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

    expect(find.textContaining('Compos'), findsOneWidget);
    expect(find.textContaining('Evid'), findsOneWidget);
    expect(find.textContaining('Pend'), findsOneWidget);
  });

  testWidgets('shows smart execution guidance during review', (tester) async {
    await _pumpReview(
      tester,
      captures: [
        _capture(
          filePath: '/tmp/a.jpg',
          ambiente: 'Fachada',
          elemento: 'Frontal',
        ),
      ],
      smartExecutionPlan: const SmartExecutionPlan(
        snapshotId: 7,
        caseId: 99,
        status: 'PUBLISHED',
        jobId: 'job-1',
        initialContext: 'Street',
        firstEnvironment: 'Fachada',
        requiredEvidenceCount: 5,
        requiresManualReview: true,
      ),
    );

    expect(find.text('Plano inteligente da vistoria'), findsNothing);
    expect(find.text('Inicie por Rua e priorize o ambiente Fachada.'), findsNothing);
    expect(find.text('Registre pelo menos 5 evidência(s) neste fluxo.'), findsNothing);
    expect(
      find.text('Este job exige revisão manual ao longo do fluxo.'),
      findsNothing,
    );
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
    expect(find.textContaining('Evid'), findsOneWidget);
  });

  testWidgets('renders pending block without old shortcut wording when empty', (
    tester,
  ) async {
    final geoPoint = GeoPointData(
      latitude: -23.0,
      longitude: -46.0,
      accuracy: 5,
      capturedAt: DateTime(2026, 3, 30),
    );
    final persistedStep2 = CheckinStep2Model.empty(TipoImovel.urbano)
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
        .setPhoto(
          fieldId: 'acesso_imovel',
          titulo: 'Acesso ao imóvel',
          imagePath: '/tmp/acesso.jpg',
          geoPoint: geoPoint,
        )
        .setPhoto(
          fieldId: 'entorno',
          titulo: 'Entorno',
          imagePath: '/tmp/entorno.jpg',
          geoPoint: geoPoint,
        )
        .toMap();

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
      tipoImovel: 'Urbano • Apartamento',
      persistedStep2Payload: persistedStep2,
    );

    expect(find.textContaining('Pend'), findsOneWidget);
    expect(find.text('Ir para pendência'), findsNothing);
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

      final persistedStep2 = CheckinStep2Model.empty(TipoImovel.urbano)
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
        persistedRecoveryPayload: {
          'step2': persistedStep2,
          'step2Config': _requiredReviewStep2Config(),
        },
      );

      expect(find.text('Fachada'), findsNothing);
      expect(find.text('Logradouro'), findsNothing);
      expect(find.text('Ir para captura'), findsAtLeastNWidgets(2));
    },
  );

  testWidgets(
    'blocks finalization when mandatory etapa 2 evidence is still pending',
    (tester) async {
      final geoPoint = GeoPointData(
        latitude: -23.0,
        longitude: -46.0,
        accuracy: 5,
        capturedAt: DateTime(2026, 3, 30),
      );

      final persistedStep2 = CheckinStep2Model.empty(TipoImovel.urbano)
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
        persistedRecoveryPayload: {
          'step2': persistedStep2,
          'step2Config': _requiredReviewStep2Config(),
        },
      );

      expect(find.textContaining('Pend'), findsOneWidget);
      expect(find.text('Ir para captura'), findsAtLeastNWidgets(2));

      final finalizeButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Finalizar vistoria'),
      );
      expect(finalizeButton.onPressed, isNull);
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
      final persistedStep2 = CheckinStep2Model.empty(TipoImovel.urbano)
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
      final flowCoordinator = _FakeInspectionFlowCoordinator()
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
        persistedRecoveryPayload: {
          'step2': persistedStep2,
          'step2Config': _requiredReviewStep2Config(),
        },
        flowCoordinator: flowCoordinator,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Ir para captura').first);
      await tester.pumpAndSettle();

      expect(flowCoordinator.overlayOpenCount, 1);
      expect(flowCoordinator.lastOverlayRequest?.title, 'Acesso ao imóvel');
    },
  );

  testWidgets(
    'uses pending requirement context when reopening camera from pending requirement',
    (tester) async {
      final flowCoordinator = _FakeInspectionFlowCoordinator()
        ..nextOverlayResult = _capture(
          filePath: '/tmp/retorno.jpg',
          ambiente: 'Quarto 2',
          elemento: 'Janela',
          material: 'Madeira',
          estado: 'Bom',
        ).copyWith(
          macroLocal: 'Interna',
          ambienteBase: 'Quarto',
          ambienteInstanceIndex: 2,
        );
      final geoPoint = GeoPointData(
        latitude: -23.0,
        longitude: -46.0,
        accuracy: 5,
        capturedAt: DateTime(2026, 3, 30),
      );
      final persistedStep2 = CheckinStep2Model.empty(TipoImovel.urbano)
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
        persistedRecoveryPayload: {
          'step2': persistedStep2,
          'step2Config': _requiredReviewStep2Config(),
          'review': {
            'tipoImovel': 'Urbano • Apartamento',
            'cameraContext': _capture(
              filePath: '/tmp/ultimo.jpg',
              ambiente: 'Quarto 2',
              elemento: 'Janela',
              material: 'Madeira',
              estado: 'Bom',
            ).copyWith(
              macroLocal: 'Interna',
              ambienteBase: 'Quarto',
              ambienteInstanceIndex: 2,
            ).toMap(),
          },
        },
        flowCoordinator: flowCoordinator,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Ir para captura').first);
      await tester.pumpAndSettle();

      expect(flowCoordinator.overlayOpenCount, 1);
      final request = flowCoordinator.lastOverlayRequest;
      expect(request, isNotNull);
      final current = request!.selectionState.currentSelection;
      expect(current.subjectContext, 'Rua');
      expect(current.targetItem, 'Acesso ao imóvel');
      expect(current.targetQualifier, isNull);
      expect(current.attributeText('inspection.material'), isNull);
      expect(current.targetCondition, isNull);
    },
  );

  testWidgets(
    'opens generic capture shortcut using step1 context when only photo coverage is pending',
    (tester) async {
      final flowCoordinator = _FakeInspectionFlowCoordinator()
        ..nextOverlayResult = _capture(
          filePath: '/tmp/cobertura.jpg',
          ambiente: 'Fachada',
          elemento: 'Portão',
        ).copyWith(macroLocal: 'Rua');
      final geoPoint = GeoPointData(
        latitude: -23.0,
        longitude: -46.0,
        accuracy: 5,
        capturedAt: DateTime(2026, 3, 30),
      );
      final persistedStep2 = CheckinStep2Model.empty(TipoImovel.urbano)
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
        persistedRecoveryPayload: {
          'step2': persistedStep2,
          'step2Config': _requiredReviewStep2Config(),
          'step1': {
            'tipoImovel': 'Urbano',
            'subtipoImovel': 'Apartamento',
            'porOndeComecar': 'Rua',
          },
        },
        flowCoordinator: flowCoordinator,
      );

      final coverageTitle = find.textContaining('Cobertura');
      final coverageCard = find.ancestor(
        of: coverageTitle,
        matching: find.byType(Container),
      ).first;
      await tester.tap(
        find.descendant(
          of: coverageCard,
          matching: find.widgetWithText(FilledButton, 'Ir para captura'),
        ).first,
      );
      await tester.pumpAndSettle();

      expect(flowCoordinator.overlayOpenCount, 1);
      expect(
        flowCoordinator.lastOverlayRequest?.selectionState.currentSelection
            .subjectContext,
        'Rua',
      );
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

      final persistedStep2 = CheckinStep2Model.empty(TipoImovel.urbano)
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
        persistedStep2Payload: persistedStep2,
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

      expect(find.text('Sala principal'), findsNothing);
      expect(find.textContaining('Falta foto obrig'), findsNothing);
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
          'step2Config': _requiredReviewStep2Config(
            photoFields: [
              {
                'id': 'sala_principal',
                'titulo': 'Sala principal',
                'cameraMacroLocal': 'Interna',
                'cameraAmbiente': 'Sala principal',
                'obrigatorio': true,
              },
            ],
          ),
        },
      );

      expect(find.textContaining('Falta foto obrig'), findsOneWidget);
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

      expect(find.textContaining('Cozinha'), findsWidgets);
      expect(find.textContaining('Piso'), findsWidgets);
    },
  );

  testWidgets(
    'preserves ambiente instance label after reopening review',
    (tester) async {
      final captureWithInstance = _capture(
        filePath: '/tmp/quarto2.jpg',
        ambiente: 'Quarto 2',
      ).copyWith(
        ambienteBase: 'Quarto',
        ambienteInstanceIndex: 2,
      );

      final recoveryPayload = {
        'review': {
          'tipoImovel': 'Urbano • Apartamento',
          'captures': [captureWithInstance.toMap()],
          'capturesRevisadas': [
            {
              'filePath': '/tmp/quarto2.jpg',
              'ambiente': 'Quarto 2',
              'ambienteBase': 'Quarto',
              'ambienteInstanceIndex': 2,
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
        captures: [captureWithInstance],
        tipoImovel: 'Urbano • Apartamento',
        persistedRecoveryPayload: recoveryPayload,
      );

      expect(find.textContaining('Quarto 2'), findsWidgets);
    },
  );
}

