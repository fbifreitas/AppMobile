import 'package:appmobile/services/inspection_camera_presentation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = InspectionCameraPresentationService.instance;

  test('builds panel presentation with checklist and suggestions state', () {
    final data = service.build(
      capturesCount: 2,
      hasPreviousPhotos: false,
      hasSelectorAmbiente: true,
      hasSelectorElemento: true,
      hasMacroLocal: true,
      hasAmbiente: true,
      singleCaptureMode: false,
      resumo: 'Interna > Quarto 2',
      contextSuggestionSummary: 'Contexto sugerido',
      predictionSummary: 'Janela • Madeira • Bom',
      recentAmbientes: const <String>['Quarto'],
      recentElementos: const <String>['Janela'],
    );

    expect(data.canOpenChecklist, isTrue);
    expect(data.showContextSuggestion, isTrue);
    expect(data.showPredictionSuggestion, isTrue);
    expect(data.showRecentAmbientes, isTrue);
    expect(data.showRecentElementos, isTrue);
    expect(data.batchSummary, contains('Quarto 2'));
    expect(data.finalizeSubtitle, '2 nova(s)');
  });
}
