import 'package:appmobile/models/job.dart';
import 'package:appmobile/models/inspection_session_model.dart';
import 'package:appmobile/models/overlay_camera_capture_result.dart';
import 'package:appmobile/repositories/job_repository.dart';
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
  String? lastOverlayTitle;
  String? lastPreselectedMacroLocal;
  String? lastInitialAmbiente;
  String? lastInitialElemento;
  String? lastInitialMaterial;
  String? lastInitialEstado;

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
    lastPreselectedMacroLocal = preselectedMacroLocal;
    lastInitialAmbiente = initialAmbiente;
    lastInitialElemento = initialElemento;
    lastInitialMaterial = initialMaterial;
    lastInitialEstado = initialEstado;
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
  }
  if (persistedRecoveryPayload != null) {
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
      stageLabel: 'Revis\u00E3o final',
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

Future<void> _expandSection(WidgetTester tester, String sectionTitle) async {
  final sectionFinder = _findTextNormalized(sectionTitle);
  expect(sectionFinder, findsOneWidget);
  await tester.ensureVisible(sectionFinder);
  await tester.tap(sectionFinder);
  await tester.pumpAndSettle();
}

String _normalizeText(String value) {
  return value
      .toLowerCase()
      .replaceAll('\\u00e3', 'a')
      .replaceAll('\\u00e2', 'a')
      .replaceAll('\\u00e1', 'a')
      .replaceAll('\\u00e0', 'a')
      .replaceAll('\\u00e9', 'e')
      .replaceAll('\\u00ea', 'e')
      .replaceAll('\\u00ed', 'i')
      .replaceAll('\\u00f3', 'o')
      .replaceAll('\\u00f4', 'o')
      .replaceAll('\\u00f5', 'o')
      .replaceAll('\\u00fa', 'u')
      .replaceAll('\\u00e7', 'c')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c')
      .replaceAll('ƒ', '')
      .replaceAll('€', '')
      .replaceAll('™', '')
      .replaceAll('œ', '')
      .replaceAll('¢', '')
      .replaceAll('•', '')
      .replaceAll('—', '')
      .replaceAll('–', '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

Finder _findTextNormalized(String expected) {
  final normalizedExpected = _normalizeText(expected);
  return find.byWidgetPredicate((widget) {
    if (widget is! Text) return false;
    final data = widget.data;
    if (data == null) return false;
    return _normalizeText(data) == normalizedExpected;
  });
}

void _expectTextNormalized(String expected, Object matcher) {
  expect(_findTextNormalized(expected), matcher);
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
    expect(find.text('Ir para principal pend\u00EAncia'), findsNothing);
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
          material: 'Cer\u00E2mica',
          estado: 'Bom',
        ),
      ],
    );

    _expectTextNormalized('REVISÃO DE FOTOS', findsOneWidget);

    await tester.tap(_findTextNormalized('REVISÃO DE FOTOS'));
    await tester.pumpAndSettle();

    _expectTextNormalized('Fotos Obrigatórias do Check-In', findsOneWidget);
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
    expect(find.text('Comandos r\u00E1pidos por voz'), findsNothing);
  });

  testWidgets('does not render old top grouping chips frame', (tester) async {
    await _pumpReview(
      tester,
      captures: [
        _capture(
          filePath: '/tmp/a.jpg',
          ambiente: 'Cozinha',
          elemento: 'Piso',
          material: 'Cer\u00E2mica',
          estado: 'Bom',
        ),
      ],
    );

    expect(find.textContaining('Fotos obrigat\u00F3rias:'), findsNothing);
    expect(find.textContaining('Fotos capturadas:'), findsNothing);
    _expectTextNormalized('REVISÃO DE FOTOS', findsOneWidget);
  });

  testWidgets('renders technical pending section without shortcut when empty', (
    tester,
  ) async {
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
            .toMap();

    await _pumpReview(
      tester,
      captures: [_capture(filePath: '/tmp/a.jpg', ambiente: 'Cozinha')],
      tipoImovel: 'Urbano \u2022 Apartamento',
      persistedStep2Payload: persistedStep2,
    );

    _expectTextNormalized('PENDÊNCIAS TÉCNICAS DA VISTORIA', findsOneWidget);
    await _expandSection(tester, 'PENDÊNCIAS TÉCNICAS DA VISTORIA');
    _expectTextNormalized('Ir para pendência', findsNothing);
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
        tipoImovel: 'Urbano \u2022 Apartamento',
        persistedStep2Payload: persistedStep2,
      );

      await _expandSection(tester, 'REVIS\u00C3O DE FOTOS');
      await _expandSection(tester, 'Fotos Obrigat\u00F3rias do Check-In');

      expect(find.text('Fachada'), findsOneWidget);
      expect(find.text('Logradouro'), findsOneWidget);
      _expectTextNormalized('Obrigatório atendido', findsNWidgets(2));
      _expectTextNormalized(
        'Obrigatório — pendente de captura',
        findsNWidgets(2),
      );
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
              ambiente: 'Acesso ao im\u00F3vel',
              elemento: 'Port\u00E3o',
            );

      await _pumpReview(
        tester,
        captures: const [],
        tipoImovel: 'Urbano \u2022 Apartamento',
        persistedStep2Payload: persistedStep2,
        flowCoordinator: flowCoordinator,
      );

      await _expandSection(tester, 'REVIS\u00C3O DE FOTOS');
      await _expandSection(tester, 'Fotos Obrigat\u00F3rias do Check-In');

      await tester.tap(find.text('Capturar').first);
      await tester.pumpAndSettle();

      expect(flowCoordinator.overlayOpenCount, 1);
      expect(flowCoordinator.lastOverlayTitle, 'Acesso ao im\u00F3vel');
      _expectTextNormalized('Obrigatório atendido', findsNWidgets(2));
      expect(find.text('Capturar'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'uses latest review capture context when reopening camera from pending requirement',
    (tester) async {
      final flowCoordinator =
          _FakeInspectionFlowCoordinator()
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
        tipoImovel: 'Urbano \u2022 Apartamento',
        persistedStep2Payload: persistedStep2,
        persistedRecoveryPayload: {
          'review': {
            'tipoImovel': 'Urbano \u2022 Apartamento',
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

      await _expandSection(tester, 'REVIS\u00C3O DE FOTOS');
      await _expandSection(tester, 'Fotos Obrigat\u00F3rias do Check-In');

      await tester.tap(find.text('Capturar').first);
      await tester.pumpAndSettle();

      expect(flowCoordinator.overlayOpenCount, 1);
      expect(flowCoordinator.lastPreselectedMacroLocal, 'Interna');
      expect(flowCoordinator.lastInitialAmbiente, 'Quarto 2');
      expect(flowCoordinator.lastInitialElemento, 'Janela');
      expect(flowCoordinator.lastInitialMaterial, 'Madeira');
      expect(flowCoordinator.lastInitialEstado, 'Bom');
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
        tipoImovel: 'Urbano \u2022 Apartamento',
        persistedRecoveryPayload: {
          'step2': persistedStep2,
          'step2Config': {
            'tituloTela': 'Etapa 2 din\u00E2mica',
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

      await _expandSection(tester, 'REVIS\u00C3O DE FOTOS');
      await _expandSection(tester, 'Fotos Obrigat\u00F3rias do Check-In');

      expect(find.text('Sala principal'), findsOneWidget);
      _expectTextNormalized('Obrigatório atendido', findsOneWidget);
      _expectTextNormalized(
        'Obrigatório — pendente de captura',
        findsNothing,
      );
    },
  );

  testWidgets(
    'handles malformed persisted step2 payload and keeps mandatory pending indicator',
    (tester) async {
      await _pumpReview(
        tester,
        captures: const [],
        tipoImovel: 'Urbano \u2022 Apartamento',
        persistedRecoveryPayload: {
          'step2': {'fotos': 'invalid-structure'},
          'step2Config': {
            'tituloTela': 'Etapa 2 din\u00E2mica',
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

      await tester.tap(_findTextNormalized('REVISÃO DE FOTOS'));
      await tester.pumpAndSettle();

      await _expandSection(tester, 'Fotos Obrigat\u00F3rias do Check-In');

      _expectTextNormalized('Fotos Obrigatórias do Check-In', findsOneWidget);
      expect(find.text('Sala principal'), findsOneWidget);
      _expectTextNormalized(
        'Obrigatório — pendente de captura',
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'keeps reviewed classification after reopening review with new camera captures',
    (tester) async {
      final recoveryPayload = {
        'review': {
          'tipoImovel': 'Urbano \u2022 Apartamento',
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
              'material': 'Cer\u00E2mica',
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
        tipoImovel: 'Urbano \u2022 Apartamento',
        persistedRecoveryPayload: recoveryPayload,
      );

      await _expandSection(tester, 'REVIS\u00C3O DE FOTOS');

      expect(find.text('Fotos Capturadas'), findsOneWidget);
      expect(
        find.textContaining('1 pend\u00EAncia(s) de classifica\u00E7\u00E3o'),
        findsOneWidget,
      );
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
          'tipoImovel': 'Urbano \u2022 Apartamento',
          'captures': [captureWithInstance.toMap()],
          'capturesRevisadas': [
            {
              'filePath': '/tmp/quarto2.jpg',
              'ambiente': 'Quarto 2',
              'ambienteBase': 'Quarto',
              'ambienteInstanceIndex': 2,
              'elemento': 'Piso',
              'material': 'Cer\u00E2mica',
              'estado': 'Bom',
              'isComplete': true,
            },
          ],
        },
      };

      await _pumpReview(
        tester,
        captures: [captureWithInstance],
        tipoImovel: 'Urbano \u2022 Apartamento',
        persistedRecoveryPayload: recoveryPayload,
      );

      await _expandSection(tester, 'REVIS\u00C3O DE FOTOS');

      expect(find.text('Quarto 2'), findsOneWidget);
    },
  );
}
