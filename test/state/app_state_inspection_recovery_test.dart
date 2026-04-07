import 'package:appmobile/models/inspection_recovery_draft.dart';
import 'package:appmobile/models/job.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ImmediateJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => <Job>[];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('beginInspectionRecovery creates recoverable draft', () async {
    final appState = AppState(_ImmediateJobRepository());
    final job = Job(
      id: 'job-1',
      titulo: 'Vistoria A',
      endereco: 'Rua A, 1',
      nomeCliente: 'Cliente A',
    );

    await appState.beginInspectionRecovery(job);

    expect(appState.inspectionRecoveryDraft, isNotNull);
    expect(appState.inspectionRecoveryDraft!.jobId, 'job-1');
    expect(appState.inspectionRecoveryDraft!.stageLabel, 'Check-in');
  });

  test('setInspectionRecoveryStage updates saved stage', () async {
    final appState = AppState(_ImmediateJobRepository());
    final job = Job(
      id: 'job-1',
      titulo: 'Vistoria A',
      endereco: 'Rua A, 1',
      nomeCliente: 'Cliente A',
    );

    appState.selecionarJob(job);
    await appState.setInspectionRecoveryStage(
      stageKey: 'fotos',
      stageLabel: 'Registro fotográfico',
      routeName: '/camera',
      payload: const {'contexto': 'fachada'},
    );

    expect(appState.inspectionRecoveryDraft, isNotNull);
    expect(appState.inspectionRecoveryDraft!.stageKey, 'fotos');
    expect(
      appState.inspectionRecoveryDraft!.stageLabel,
      'Registro fotográfico',
    );
  });

  test('clearInspectionRecovery removes saved draft', () async {
    final appState = AppState(_ImmediateJobRepository());
    final job = Job(
      id: 'job-1',
      titulo: 'Vistoria A',
      endereco: 'Rua A, 1',
      nomeCliente: 'Cliente A',
    );

    await appState.beginInspectionRecovery(job);
    await appState.clearInspectionRecovery();

    expect(appState.inspectionRecoveryDraft, isNull);
  });

  test('prioritizeRecoveryJob moves interrupted job to first position', () {
    final appState = AppState(_ImmediateJobRepository());
    appState.jobs = [
      Job(id: 'job-1', titulo: 'A', endereco: 'Rua A', nomeCliente: 'A'),
      Job(id: 'job-2', titulo: 'B', endereco: 'Rua B', nomeCliente: 'B'),
    ];
    appState.inspectionRecoveryDraft = InspectionRecoveryDraft.initial(
      jobId: 'job-2',
    );

    appState.prioritizeRecoveryJob();

    expect(appState.jobs.first.id, 'job-2');
  });

  test(
    'persistStep2Draft preserves current stage and dynamic step2 config',
    () async {
      final appState = AppState(_ImmediateJobRepository());
      final job = Job(
        id: 'job-1',
        titulo: 'Vistoria A',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
      );

      appState.selecionarJob(job);
      await appState.setInspectionRecoveryStage(
        stageKey: 'inspection_review',
        stageLabel: 'Revisão final',
        routeName: '/inspection_review',
        payload: {
          'step1': {'tipoImovel': 'Urbano'},
          'step2Config': {
            'tituloTela': 'Etapa 2 dinâmica',
            'camposFotos': [
              {
                'id': 'fachada',
                'titulo': 'Fachada',
                'cameraMacroLocal': 'Rua',
                'cameraAmbiente': 'Fachada',
                'obrigatorio': true,
              },
            ],
          },
        },
      );

      await appState.persistStep2Draft({
        'fotos': {
          'fachada': {'imagePath': '/tmp/fachada.jpg'},
        },
      });

      expect(appState.inspectionRecoveryDraft, isNotNull);
      expect(appState.inspectionRecoveryDraft!.stageKey, 'inspection_review');
      expect(appState.inspectionRecoveryDraft!.routeName, '/inspection_review');
      expect(appState.step2Payload['fotos'], isA<Map<String, dynamic>>());
      expect(
        appState.inspectionRecoveryPayload['step2Config'],
        isA<Map<String, dynamic>>(),
      );
    },
  );

  test('atualizarReferenciasExternasJob updates finalized job by id', () {
    final appState = AppState(_ImmediateJobRepository());
    appState.jobs = [
      Job(
        id: 'job-1',
        titulo: 'Vistoria A',
        endereco: 'Rua A, 1',
        nomeCliente: 'Cliente A',
      ),
      Job(
        id: 'job-2',
        titulo: 'Vistoria B',
        endereco: 'Rua B, 2',
        nomeCliente: 'Cliente B',
      ),
    ];

    appState.atualizarReferenciasExternasJob(
      jobId: 'job-2',
      idExterno: 'proc-2',
      protocoloExterno: 'INS-2026-0002',
    );

    expect(appState.jobs.first.idExterno, isNull);
    expect(appState.jobs.first.protocoloExterno, isNull);
    expect(appState.jobs.last.idExterno, 'proc-2');
    expect(appState.jobs.last.protocoloExterno, 'INS-2026-0002');
  });
}
