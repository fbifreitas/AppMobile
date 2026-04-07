import 'package:appmobile/models/job.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:appmobile/widgets/home/jobs_section.dart';
import 'package:flutter/material.dart';
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

  testWidgets('shows Retomar Vistoria for recoverable job', (tester) async {
    final appState = AppState(_ImmediateJobRepository());
    final job = Job(
      id: 'job-1',
      titulo: 'Vistoria A',
      endereco: 'Rua A',
      nomeCliente: 'Cliente A',
      latitude: -23.0,
      longitude: -46.0,
      tipoImovel: 'Urbano',
      subtipoImovel: 'Casa',
    );
    appState.jobs = [job];

    await appState.beginInspectionRecovery(job);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobsSection(
            appState: appState,
            currentLatitude: -23.0,
            currentLongitude: -46.0,
            useDistanceMetrics: true,
            onNavigateToJob: ({
              required double? latitude,
              required double? longitude,
              required String address,
            }) async {},
            onStartInspection: (_) async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('RETOMAR VISTORIA'), findsOneWidget);
    expect(find.text('EM RECUPERAÇÃO'), findsOneWidget);
    expect(find.textContaining('Última etapa salva: Check-in'), findsOneWidget);
  });
}
