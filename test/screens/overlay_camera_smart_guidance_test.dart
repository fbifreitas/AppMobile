import 'package:appmobile/models/flow_selection.dart';
import 'package:appmobile/models/job.dart';
import 'package:appmobile/models/smart_execution_plan.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/screens/overlay_camera_screen.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _ImmediateJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => <Job>[];
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxTicks = 40,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

FlowSelectionState _flowState({
  String? macroLocal,
  String? ambiente,
}) {
  final selection = FlowSelection(
    subjectContext: macroLocal,
    targetItem: ambiente,
  );
  return FlowSelectionState(
    initialSuggestedSelection: selection,
    currentSelection: selection,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'OverlayCameraScreen keeps evidence target without rendering smart guidance copy',
    (tester) async {
      final appState = AppState(_ImmediateJobRepository());
      appState.selecionarJob(
        Job(
          id: 'job-1',
          titulo: 'Vistoria A',
          endereco: 'Rua A, 1',
          nomeCliente: 'Cliente A',
          smartExecutionPlan: const SmartExecutionPlan(
            snapshotId: 7,
            caseId: 99,
            status: 'PUBLISHED',
            jobId: 'job-1',
            initialContext: 'Street',
            firstEnvironment: 'Fachada',
            requiredEvidenceCount: 5,
            requiresManualReview: true,
            capturePlan: [
              SmartExecutionCapturePlanItem(
                macroLocal: 'Street',
                environment: 'Fachada',
                element: 'Porta principal',
                required: true,
                minPhotos: 2,
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: OverlayCameraScreen(
              title: 'Camera',
              tipoImovel: 'Urbano',
              subtipoImovel: 'Casa',
              initialFlowState: _flowState(
                macroLocal: 'Rua',
                ambiente: 'Fachada',
              ),
              useTestMenuData: true,
              testCameraLevelOrder: const <String>['ambiente'],
              testMacroLocais: const <String>['Rua'],
              testAmbientes: const <String>['Fachada'],
              skipDeviceInitialization: true,
              showVoiceActions: false,
            ),
          ),
        ),
      );

      await _pumpUntilFound(tester, find.textContaining('Capturas no lote: 0/5'));

      expect(find.textContaining('Plano inteligente da vistoria:'), findsNothing);
      expect(
        find.textContaining(
          'Próxima evidência sugerida: Rua > Fachada > Porta principal.',
        ),
        findsNothing,
      );
      expect(find.textContaining('Capturas no lote: 0/5'), findsOneWidget);
    },
  );
}
