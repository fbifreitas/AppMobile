import 'package:appmobile/models/job.dart';
import 'package:appmobile/models/job_status.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/screens/completed_inspections_screen.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => [];
}

void main() {
  testWidgets('shows external id and protocol in completed inspection list', (
    tester,
  ) async {
    final appState = AppState(_FakeJobRepository());
    appState.jobs = [
      Job(
        id: 'job-1',
        titulo: 'Vistoria concluida',
        endereco: 'Rua A, 100',
        nomeCliente: 'Cliente A',
        status: JobStatus.finalizado,
        idExterno: 'ext-123',
        protocoloExterno: '190108',
      ),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(home: CompletedInspectionsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ID externo: ext-123'), findsOneWidget);
    expect(find.text('Protocolo: 190108'), findsOneWidget);
  });
}
