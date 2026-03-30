import 'package:appmobile/models/job.dart';
import 'package:appmobile/repositories/job_repository.dart';
import 'package:appmobile/screens/inspection_review_screen.dart';
import 'package:appmobile/screens/overlay_camera_screen.dart';
import 'package:appmobile/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void Function(FlutterErrorDetails)? _originalFlutterErrorHandler;

class _ImmediateJobRepository implements JobRepository {
  @override
  Future<List<Job>> getJobs() async => <Job>[];
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
}) async {
  tester.view.physicalSize = const Size(1440, 2560);
  tester.view.devicePixelRatio = 1.0;

  final appState = AppState(_ImmediateJobRepository());

  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: InspectionReviewScreen(
          captures: captures,
          tipoImovel: 'Urbano',
          cameFromCheckinStep1: false,
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
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first.resetPhysicalSize();
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('shows review CTA without pending shortcut link', (tester) async {
    await _pumpReview(
      tester,
      captures: [
        _capture(filePath: '/tmp/a.jpg', ambiente: 'Cozinha'),
      ],
    );

    expect(find.text('REVISAR E FINALIZAR'), findsOneWidget);
    expect(find.text('Ir para principal pendência'), findsNothing);
  });

  testWidgets('consolidates pending content under one review section', (tester) async {
    await _pumpReview(
      tester,
      captures: [
        _capture(filePath: '/tmp/a.jpg', ambiente: 'Cozinha', elemento: 'Piso', material: 'Cerâmica', estado: 'Bom'),
      ],
    );

    expect(find.textContaining('Ver pendências da vistoria'), findsOneWidget);
    expect(find.text('Fotos obrigatórias do check-in'), findsOneWidget);
    expect(find.text('Fotos capturadas'), findsOneWidget);
  });

  testWidgets('does not render optional voice commands section', (tester) async {
    await _pumpReview(
      tester,
      captures: [
        _capture(filePath: '/tmp/a.jpg', ambiente: 'Cozinha'),
      ],
    );

    expect(find.text('Comandos por voz (opcional)'), findsNothing);
    expect(find.text('Comandos rápidos por voz'), findsNothing);
  });

  testWidgets('uses simplified progress header without top metric chips', (tester) async {
    await _pumpReview(
      tester,
      captures: [
        _capture(filePath: '/tmp/a.jpg', ambiente: 'Cozinha', elemento: 'Piso', material: 'Cerâmica', estado: 'Bom'),
      ],
    );

    expect(find.text('Revisão de fotos'), findsOneWidget);
    expect(find.text('Concluídas'), findsNothing);
    expect(find.text('Pendências'), findsNothing);
  });
}
