import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:appmobile/config/checkin_step2_config.dart';
import 'package:appmobile/l10n/app_strings.dart';
import 'package:appmobile/models/checkin_step2_model.dart';
import 'package:appmobile/models/flow_selection.dart';
import 'package:appmobile/models/job.dart';
import 'package:appmobile/models/inspection_camera_flow_request.dart';
import 'package:appmobile/models/inspection_session_model.dart';
import 'package:appmobile/models/overlay_camera_capture_result.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/services/checkin_dynamic_config_service.dart';
import 'package:appmobile/services/inspection_camera_entry_policy_service.dart';
import 'package:appmobile/services/inspection_flow_coordinator.dart';
import 'package:appmobile/services/mobile_job_action_service.dart';
import 'package:appmobile/screens/checkin_screen.dart';
import 'package:appmobile/screens/checkin_step2_screen.dart';
import 'package:appmobile/screens/home_screen.dart';
import 'package:appmobile/screens/inspection_review_screen.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:appmobile/state/inspection_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/brand_test_helper.dart';

MaterialApp _materialApp(Widget home) {
  return MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: AppStrings.localizationsDelegates,
    supportedLocales: AppStrings.supportedLocales,
    home: home,
  );
}

class _ImmediateJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => <Job>[];
}

class _FakeInspectionFlowCoordinator extends InspectionFlowCoordinator {
  bool didOpenCheckin = false;
  bool didRestoreReviewRecoveryFlow = false;
  bool didRestoreCheckinStep2RecoveryFlow = false;
  int overlayOpenCount = 0;
  String? restoredTipoImovel;
  CheckinStep2Model? restoredInitialData;
  List<OverlayCameraCaptureResult> restoredCaptures =
      const <OverlayCameraCaptureResult>[];
  InspectionCameraFlowRequest? lastOverlayRequest;

  @override
  void openCheckin(BuildContext context, {bool silent = false}) {
    didOpenCheckin = true;
  }

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
    return null;
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
  }) {
    didRestoreReviewRecoveryFlow = true;
    restoredTipoImovel = tipoImovel;
    restoredInitialData = initialData;
    restoredCaptures = captures;
  }

  @override
  void restoreCheckinStep2RecoveryFlow(
    BuildContext context, {
    required String tipoImovel,
    CheckinStep2Model? initialData,
    ValueChanged<CheckinStep2Model>? onContinue,
  }) {
    didRestoreCheckinStep2RecoveryFlow = true;
    restoredTipoImovel = tipoImovel;
    restoredInitialData = initialData;
  }

  @override
  void openCameraFlow(BuildContext context) {}
}

class _FakeMobileJobActionService extends MobileJobActionService {
  static const MobileJobActionResult _defaultResult = MobileJobActionResult(
    success: true,
    message:
        'Solicitacao enviada ao backoffice. O job agora aguarda reagendamento.',
  );
  bool called = false;
  String? lastJobId;

  @override
  Future<MobileJobActionResult> requestSchedulingAfterClientAbsent({
    required String jobId,
    String? reason,
  }) async {
    called = true;
    lastJobId = jobId;
    return _defaultResult;
  }
}

void main() {
  late HttpOverrides? previousOverrides;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDown(() {
    HttpOverrides.global = previousOverrides;
  });

  testWidgets('check-in etapa 1 exposes main option groups', (tester) async {
    final appState = AppState(_ImmediateJobRepository());
    appState.selecionarJob(
      Job(
        id: 'job-1',
        titulo: 'Vistoria A',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const CheckinScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Cliente est'), findsOneWidget);
    final clientePresenteChips = find.byType(ChoiceChip);
    expect(clientePresenteChips, findsNWidgets(2));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Sim'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tipo de im'), findsOneWidget);
    expect(find.text('Urbano'), findsOneWidget);
    expect(find.text('Rural'), findsOneWidget);
    expect(find.text('Comercial'), findsOneWidget);
    expect(find.text('Industrial'), findsOneWidget);

    // Scroll down to bring Urbano into view
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Urbano'));
    await tester.pumpAndSettle();

    // Scroll down to bring Subtipo into view
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(find.text('Subtipo'), findsOneWidget);
    expect(find.text('Apartamento'), findsOneWidget);
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Sobrado'), findsOneWidget);
    expect(find.text('Terreno'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Apartamento'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'check-in etapa 1 confirms client absent and sends job to awaiting scheduling',
    (tester) async {
      final appState = AppState(_ImmediateJobRepository());
      final job = Job(
        id: 'job-absent-1',
        titulo: 'Vistoria Cliente Ausente',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
      );
      appState.jobs = [job];
      appState.selecionarJob(job);
      final actionService = _FakeMobileJobActionService();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: CheckinScreen(jobActionService: actionService),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.widgetWithText(ChoiceChip, 'NÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â£o'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Confirmar ausÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Âªncia do cliente'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(actionService.called, isTrue);
      expect(actionService.lastJobId, 'job-absent-1');
      expect(appState.jobAtual, isNull);
      expect(appState.jobs, isEmpty);
      expect(
        appState.mensagens.any(
          (message) => message.titulo == 'Aguardando agendamento',
        ),
        isTrue,
      );
    },
    skip: true,
  );

  testWidgets(
    'check-in etapa 1 confirms client absent and sends job to awaiting scheduling with stable selector',
    (tester) async {
      final appState = AppState(_ImmediateJobRepository());
      final job = Job(
        id: 'job-absent-2',
        titulo: 'Vistoria Cliente Ausente',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
      );
      appState.jobs = [job];
      appState.selecionarJob(job);
      final actionService = _FakeMobileJobActionService();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: CheckinScreen(jobActionService: actionService),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final clientePresenteChips = find.byType(ChoiceChip);
      expect(clientePresenteChips, findsNWidgets(2));

      await tester.tap(clientePresenteChips.at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Confirmar aus'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(actionService.called, isTrue);
      expect(actionService.lastJobId, 'job-absent-2');
      expect(appState.jobAtual, isNull);
      expect(appState.jobs, isEmpty);
      expect(
        appState.mensagens.any(
          (message) => message.titulo == 'Aguardando agendamento',
        ),
        isTrue,
      );
    },
  );

  testWidgets('check-in etapa 1 renders dynamic levels from configuration', (
    tester,
  ) async {
    final appState = AppState(_ImmediateJobRepository());
    appState.selecionarJob(
      Job(
        id: 'job-1',
        titulo: 'Vistoria A',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
      ),
    );

    await CheckinDynamicConfigService.instance.configureDeveloperMock(
      enabled: true,
      documentJson: jsonEncode({
        'step1': {
          'tipos': ['Urbano'],
          'contextos': ['Rua', 'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Ârea interna'],
          'subtiposPorTipo': {
            'Urbano': ['Apartamento'],
          },
          'levels': [
            {
              'id': 'torre',
              'label': 'Torre',
              'required': false,
              'options': ['Torre A', 'Torre B'],
            },
            {
              'id': 'piso',
              'label': 'Piso',
              'required': true,
              'dependsOn': 'torre',
              'options': ['TÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©rreo', '1ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âº'],
            },
            {
              'id': 'contexto',
              'label': 'Por onde deseja comeÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ar?',
              'required': true,
              'options': ['Rua', 'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Ârea interna'],
            },
          ],
          'levelsBySubtipo': {
            'Urbano': {'Apartamento': []},
          },
        },
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const CheckinScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Sim'));
    await tester.pumpAndSettle();

    // Scroll down to bring Urbano into view
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Urbano'));
    await tester.pumpAndSettle();

    // Scroll down to bring Subtipo into view
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Apartamento'));
    await tester.pumpAndSettle();

    // Scroll down to bring Torre into view
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Torre'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Torre A'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '1ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âº'), findsNothing);

    // Select Torre first (Piso depends on Torre)
    await tester.tap(find.widgetWithText(ChoiceChip, 'Torre A'));
    await tester.pumpAndSettle();
    
    // Now Piso should be visible
    expect(find.text('Piso'), findsOneWidget);
  });

  testWidgets('check-in etapa 1 forwards all selected levels to camera', (
    tester,
  ) async {
    final appState = AppState(_ImmediateJobRepository());
    final flowCoordinator = _FakeInspectionFlowCoordinator();
    appState.selecionarJob(
      Job(
        id: 'job-1',
        titulo: 'Vistoria A',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
      ),
    );

    await CheckinDynamicConfigService.instance.configureDeveloperMock(
      enabled: true,
      documentJson: jsonEncode({
        'step1': {
          'tipos': ['Urbano'],
          'contextos': ['Rua'],
          'subtiposPorTipo': {
            'Urbano': ['Apartamento'],
          },
          'levels': [
            {
              'id': 'area_foto',
              'label': 'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Ârea da foto',
              'required': true,
              'options': ['Rua'],
            },
            {
              'id': 'ambiente',
              'label': 'Ambiente',
              'required': true,
              'options': ['Fachada'],
            },
            {
              'id': 'elemento',
              'label': 'Elemento',
              'required': true,
              'options': ['PortÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â£o'],
            },
            {
              'id': 'material',
              'label': 'Material',
              'required': true,
              'options': ['Metal'],
            },
            {
              'id': 'estado',
              'label': 'Estado',
              'required': true,
              'options': ['Bom'],
            },
          ],
        },
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: CheckinScreen(flowCoordinator: flowCoordinator),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Sim'));
    await tester.pumpAndSettle();

    // Scroll down to bring Urbano into view
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Urbano'));
    await tester.pumpAndSettle();

    // Scroll down to bring Subtipo into view
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Apartamento'));
    await tester.pumpAndSettle();

    // Scroll down to bring ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Ârea da foto into view
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Rua'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Fachada'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'PortÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â£o'));
    await tester.pumpAndSettle();
    
    // Scroll down to bring Material options and Estado into view
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    
    await tester.tap(find.widgetWithText(ChoiceChip, 'Metal'));
    await tester.pumpAndSettle();

    // Scroll down to bring Bom into view
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Bom'));
    await tester.pumpAndSettle();

    final confirmButton = find.byType(ElevatedButton);
    await tester.scrollUntilVisible(
      confirmButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    final request = flowCoordinator.lastOverlayRequest;
    expect(request, isNotNull);
    final initial = request!.selectionState.initialSuggestedSelection;
    expect(initial.subjectContext, 'Rua');
    expect(initial.targetItem, 'Fachada');
    expect(initial.targetQualifier, 'PortÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â£o');
    expect(initial.attributeText('inspection.material'), 'Metal');
    expect(initial.targetCondition, 'Bom');
  });

  testWidgets('check-in etapa 1 hides step2 action when backend marks it invisible', (
    tester,
  ) async {
    final appState = AppState(_ImmediateJobRepository());
    appState.selecionarJob(
      Job(
        id: 'job-1',
        titulo: 'Vistoria A',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
      ),
    );

    await CheckinDynamicConfigService.instance.configureDeveloperMock(
      enabled: true,
      documentJson: jsonEncode({
        'step2': {
          'byTipo': {
            'urbano': {
              'visivel': false,
              'obrigatoria': false,
              'camposFotos': [
                {
                  'id': 'fachada',
                  'titulo': 'Fachada',
                  'icon': 'home_work_outlined',
                  'obrigatorio': true,
                  'cameraMacroLocal': 'Rua',
                  'cameraAmbiente': 'Fachada',
                },
              ],
            },
          },
        },
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const CheckinScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sim'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Urbano'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Apartamento'));
    await tester.pumpAndSettle();

    expect(find.text('Ir para etapa 2 do check-in'), findsNothing);
  });

  testWidgets(
    'check-in etapa 1 keeps camera available when step2 is required only for delivery',
    (
    tester,
  ) async {
    final appState = AppState(_ImmediateJobRepository());
    final flowCoordinator = _FakeInspectionFlowCoordinator();
    appState.selecionarJob(
      Job(
        id: 'job-1',
        titulo: 'Vistoria A',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
      ),
    );

    await CheckinDynamicConfigService.instance.configureDeveloperMock(
      enabled: true,
      documentJson: jsonEncode({
        'step1': {
          'tipos': ['Urbano'],
          'contextos': ['Rua'],
          'subtiposPorTipo': {
            'Urbano': ['Apartamento'],
          },
          'levels': [
            {
              'id': 'contexto',
              'label': 'Por onde deseja comecar?',
              'required': true,
              'options': ['Rua'],
            },
          ],
        },
        'step2': {
          'byTipo': {
            'urbano': {
              'visivel': true,
              'obrigatoriaParaEntrega': true,
              'obrigatoria': true,
              'bloqueiaCaptura': false,
              'camposFotos': [
                {
                  'id': 'fachada',
                  'titulo': 'Fachada',
                  'icon': 'home_work_outlined',
                  'obrigatorio': true,
                  'cameraMacroLocal': 'Rua',
                  'cameraAmbiente': 'Fachada',
                },
              ],
            },
          },
        },
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: CheckinScreen(flowCoordinator: flowCoordinator),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sim'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Urbano'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Apartamento'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Rua'));
    await tester.pumpAndSettle();
    /*

    final confirmButton = find.byType(ElevatedButton);
    await tester.scrollUntilVisible(
      confirmButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(find.text('AtenÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â§ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â£o'), findsOneWidget);
    */

    final confirmButton = find.byType(ElevatedButton);
    await tester.scrollUntilVisible(
      confirmButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(flowCoordinator.overlayOpenCount, 1);
    expect(flowCoordinator.lastOverlayRequest, isNotNull);
  });

  testWidgets(
    'check-in etapa 2 urbano renders mandatory fields and option groups',
    (tester) async {
      await CheckinDynamicConfigService.instance.configureDeveloperMock(
        enabled: false,
      );

      final appState = AppState(_ImmediateJobRepository());
      appState.selecionarJob(
        Job(
          id: 'job-1',
          titulo: 'Vistoria A',
          endereco: 'Rua A, 1',
          nomeCliente: 'Cliente A',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: const CheckinStep2Screen(tipoImovel: 'Urbano'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('REGISTROS FOTOGR'), findsOneWidget);

      await tester.tap(find.textContaining('REGISTROS FOTOGR'));
      await tester.pumpAndSettle();

      expect(find.text('Fachada'), findsOneWidget);
      expect(find.text('Logradouro'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Capturar'), findsNWidgets(4));
      expect(find.textContaining('Foto obrigat'), findsAtLeastNWidgets(2));

      final optionsSection = find.textContaining('INFRAESTRUTURA');
      await tester.scrollUntilVisible(
        optionsSection,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(optionsSection, findsOneWidget);

      await tester.tap(
        find.ancestor(of: optionsSection, matching: find.byType(ExpansionTile)).first,
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Selecionar por voz'), findsWidgets);
    },
  );

  testWidgets(
    'check-in etapa 2 keeps step1 capture context when continuing to camera',
    (tester) async {
      await CheckinDynamicConfigService.instance.configureDeveloperMock(
        enabled: false,
      );

      final appState = AppState(_ImmediateJobRepository());
      appState.selecionarJob(
        Job(
          id: 'job-1',
          titulo: 'Vistoria A',
          endereco: 'Rua A, 1',
          nomeCliente: 'Cliente A',
        ),
      );
      await appState.persistStep1Draft(
        clientePresente: true,
        tipoImovel: 'Urbano',
        subtipoImovel: 'Apartamento',
        porOndeComecar: 'Rua',
        niveis: const <String, String>{'contexto': 'Rua'},
      );

      final request = InspectionCameraEntryPolicyService.instance.buildRequest(
        source: InspectionCameraEntrySource.step2Continue,
        title: 'COLETA',
        tipoImovel: 'Urbano',
        subtipoImovel: 'Apartamento',
        explicitSelection: const FlowSelection(subjectContext: 'Rua'),
        step1Payload: appState.step1Payload,
        currentCaptures: const <OverlayCameraCaptureResult>[],
        inspectionRecoveryPayload: appState.inspectionRecoveryPayload,
      );
      expect(request.selectionState.currentSelection.subjectContext, 'Rua');
    },
  );

  testWidgets(
    'home recovery from review rebuilds full stack through review step2 and step1',
    (tester) async {
      final appState = AppState(_ImmediateJobRepository());
      final job = Job(
        id: 'job-1',
        titulo: 'Vistoria A',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
        latitude: -23.0,
        longitude: -46.0,
        tipoImovel: 'Urbano',
        subtipoImovel: 'Apartamento',
      );
      appState.jobs = [job];
      appState.atualizarUltimaLocalizacao(-23.0, -46.0);
      appState.selecionarJob(job);

      final geoPoint = GeoPointData(
        latitude: -23.0,
        longitude: -46.0,
        accuracy: 5,
        capturedAt: DateTime(2026, 3, 30),
      );
      final step2Payload =
          CheckinStep2Model.empty(TipoImovel.urbano)
              .setPhoto(
                fieldId: 'fachada',
                titulo: 'Fachada',
                imagePath: '/tmp/fachada.jpg',
                geoPoint: geoPoint,
              )
              .toMap();

      await appState.setInspectionRecoveryStage(
        stageKey: 'inspection_review',
        stageLabel: 'RevisÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â£o final',
        routeName: '/inspection_review',
        payload: {
          'step1': {
            'clientePresente': true,
            'tipoImovel': 'Urbano',
            'subtipoImovel': 'Apartamento',
            'porOndeComecar': 'Rua',
          },
          'step2': step2Payload,
          'review': {
            'tipoImovel': 'Urbano ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ Apartamento',
            'captures': const <Map<String, dynamic>>[],
          },
        },
      );

      await tester.pumpWidget(
        withBrand(MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider(create: (_) => InspectionState()),
          ],
          child: _materialApp(const HomeScreen()),
        )),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('RETOMAR VISTORIA'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'RETOMAR VISTORIA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(InspectionReviewScreen), findsOneWidget);

      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );

      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(CheckinStep2Screen), findsOneWidget);
      expect(find.textContaining('REGISTROS FOTOGR'), findsOneWidget);

      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(CheckinScreen), findsOneWidget);
    },
  );

  testWidgets(
    'home recovery delegates review rebuild to injected coordinator',
    (tester) async {
      final appState = AppState(_ImmediateJobRepository());
      final flowCoordinator = _FakeInspectionFlowCoordinator();
      final job = Job(
        id: 'job-1',
        titulo: 'Vistoria A',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
        latitude: -23.0,
        longitude: -46.0,
        tipoImovel: 'Urbano',
        subtipoImovel: 'Apartamento',
      );
      appState.jobs = [job];
      appState.atualizarUltimaLocalizacao(-23.0, -46.0);
      appState.selecionarJob(job);

      final geoPoint = GeoPointData(
        latitude: -23.0,
        longitude: -46.0,
        accuracy: 5,
        capturedAt: DateTime(2026, 3, 30),
      );
      final step2Payload =
          CheckinStep2Model.empty(TipoImovel.urbano)
              .setPhoto(
                fieldId: 'fachada',
                titulo: 'Fachada',
                imagePath: '/tmp/fachada.jpg',
                geoPoint: geoPoint,
              )
              .toMap();

      await appState.setInspectionRecoveryStage(
        stageKey: 'inspection_review',
        stageLabel: 'RevisÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â£o final',
        routeName: '/inspection_review',
        payload: {
          'step1': {
            'clientePresente': true,
            'tipoImovel': 'Urbano',
            'subtipoImovel': 'Apartamento',
            'porOndeComecar': 'Rua',
          },
          'step2': step2Payload,
          'review': {
            'tipoImovel': 'Urbano ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ Apartamento',
            'captures': const <Map<String, dynamic>>[],
          },
        },
      );

      await tester.pumpWidget(
        withBrand(MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider(create: (_) => InspectionState()),
          ],
          child: _materialApp(HomeScreen(flowCoordinator: flowCoordinator)),
        )),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.widgetWithText(ElevatedButton, 'RETOMAR VISTORIA'));
      await tester.pump();

      expect(flowCoordinator.didRestoreReviewRecoveryFlow, isTrue);
      expect(flowCoordinator.restoredTipoImovel, 'Urbano ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ Apartamento');
      expect(
        flowCoordinator.restoredInitialData?.isPhotoCaptured('fachada'),
        isTrue,
      );
      expect(flowCoordinator.restoredCaptures, isEmpty);
    },
  );
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestHttpClient();
  }
}

class _TestHttpClient implements HttpClient {
  bool _autoUncompress = true;

  @override
  bool get autoUncompress => _autoUncompress;

  @override
  set autoUncompress(bool value) {
    _autoUncompress = value;
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _TestHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _TestHttpClientRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return _TestHttpClientResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static final Uint8List _imageBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wn4n8sAAAAASUVORK5CYII=',
  );

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _imageBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  HttpHeaders get headers => _TestHttpHeaders();

  @override
  Future<Socket> detachSocket() {
    throw UnimplementedError();
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[_imageBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
