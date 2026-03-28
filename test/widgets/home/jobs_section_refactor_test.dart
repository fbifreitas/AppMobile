import 'package:appmobile/models/job.dart';
import 'package:appmobile/models/job_status.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:appmobile/widgets/home/jobs_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ImmediateJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => <Job>[];
}

void main() {
  testWidgets('JobsSection renders on-site distance labels', (tester) async {
    final appState = AppState(_ImmediateJobRepository());
    appState.jobs = [
      Job(
        id: '1',
        titulo: 'Vistoria teste',
        endereco: 'Rua A, 100',
        nomeCliente: 'Cliente Teste',
        status: JobStatus.aceito,
        latitude: -23.0,
        longitude: -46.0,
      ),
    ];

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
            onStartInspection: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Você está no local'), findsOneWidget);
    expect(find.text('Dentro do raio'), findsOneWidget);
    expect(find.text('INICIAR VISTORIA'), findsOneWidget);
  });
}
