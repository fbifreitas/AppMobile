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
  Job buildJob({
    required String tipo,
    required String? subtipo,
    required double latitude,
    required double longitude,
  }) {
    return Job(
      id: '1',
      titulo: 'Vistoria teste',
      endereco: 'Rua A, 100',
      nomeCliente: 'Cliente Teste',
      status: JobStatus.aceito,
      latitude: latitude,
      longitude: longitude,
      tipoImovel: tipo,
      subtipoImovel: subtipo,
    );
  }

  testWidgets('disables iniciar vistoria outside radius when developer mode is off',
      (tester) async {
    final appState = AppState(_ImmediateJobRepository());
    appState.developerModeEnabled = false;
    appState.permitirIniciarLonge = false;
    appState.jobs = [
      buildJob(
        tipo: 'Urbano',
        subtipo: 'Casa',
        latitude: -23.0100,
        longitude: -46.0100,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobsSection(
            appState: appState,
            currentLatitude: -23.0000,
            currentLongitude: -46.0000,
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

    expect(find.text('INICIAR VISTORIA'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'INICIAR VISTORIA'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows iniciar dev outside radius when developer mode is on',
      (tester) async {
    final appState = AppState(_ImmediateJobRepository());
    appState.developerModeEnabled = true;
    appState.permitirIniciarLonge = true;
    appState.jobs = [
      buildJob(
        tipo: 'Urbano',
        subtipo: 'Casa',
        latitude: -23.0100,
        longitude: -46.0100,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobsSection(
            appState: appState,
            currentLatitude: -23.0000,
            currentLongitude: -46.0000,
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

    expect(find.text('INICIAR (DEV)'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'INICIAR (DEV)'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('enables iniciar vistoria when user is inside the configured radius',
      (tester) async {
    final appState = AppState(_ImmediateJobRepository());
    appState.developerModeEnabled = false;
    appState.permitirIniciarLonge = false;
    appState.jobs = [
      buildJob(
        tipo: 'Urbano',
        subtipo: 'Casa',
        latitude: -23.0003,
        longitude: -46.0003,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobsSection(
            appState: appState,
            currentLatitude: -23.0000,
            currentLongitude: -46.0000,
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

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'INICIAR VISTORIA'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('uses apartment radius when job subtype is apartamento',
      (tester) async {
    final appState = AppState(_ImmediateJobRepository());
    appState.developerModeEnabled = false;
    appState.permitirIniciarLonge = false;
    appState.jobs = [
      buildJob(
        tipo: 'Urbano',
        subtipo: 'Apartamento',
        latitude: -23.0009,
        longitude: -46.0000,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobsSection(
            appState: appState,
            currentLatitude: -23.0000,
            currentLongitude: -46.0000,
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

    expect(find.text('Raio: 150m'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'INICIAR VISTORIA'),
    );
    expect(button.onPressed, isNotNull);
  });
}
