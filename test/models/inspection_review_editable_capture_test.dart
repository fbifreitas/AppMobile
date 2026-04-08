/// BL-069: Contrato de InspectionReviewEditableCapture — selection e applySelection.
library;

import 'package:appmobile/models/flow_selection.dart';
import 'package:appmobile/models/inspection_review_models.dart';
import 'package:appmobile/models/overlay_camera_capture_result.dart';
import 'package:flutter_test/flutter_test.dart';

InspectionReviewEditableCapture _buildCapture({
  String filePath = 'test.jpg',
  String? macroLocal,
  String ambiente = 'Sala',
  String? ambienteBase,
  int? ambienteInstanceIndex,
  String? elemento,
  String? material,
  String? estado,
}) {
  return InspectionReviewEditableCapture(
    filePath: filePath,
    macroLocal: macroLocal,
    ambiente: ambiente,
    ambienteBase: ambienteBase,
    ambienteInstanceIndex: ambienteInstanceIndex,
    elemento: elemento,
    material: material,
    estado: estado,
    capturedAt: DateTime(2026, 1, 1),
    status: InspectionReviewPhotoStatus.pending,
  );
}

void main() {
  group('InspectionReviewEditableCapture — selection getter', () {
    test('mapeia campos domain para FlowSelection canônico', () {
      final item = _buildCapture(
        macroLocal: 'Área interna',
        ambiente: 'Sala 2',
        ambienteBase: 'Sala',
        ambienteInstanceIndex: 2,
        elemento: 'Piso',
        material: 'Cerâmico',
        estado: 'Regular',
      );

      final sel = item.selection;
      expect(sel.subjectContext, 'Área interna');
      expect(sel.targetItem, 'Sala 2');
      expect(sel.targetItemBase, 'Sala');
      expect(sel.targetItemInstanceIndex, 2);
      expect(sel.targetQualifier, 'Piso');
      expect(sel.targetCondition, 'Regular');
      expect(sel.attributeText('inspection.material'), 'Cerâmico');
    });

    test('material null não aparece em domainAttributes', () {
      final item = _buildCapture(elemento: 'Porta');
      expect(item.selection.domainAttributes, isEmpty);
    });
  });

  group('InspectionReviewEditableCapture — applySelection', () {
    test('aplica seleção completa sobre item existente', () {
      final item = _buildCapture(ambiente: 'Sala');
      final newSel = FlowSelection(
        subjectContext: 'Rua',
        targetItem: 'Fachada',
        targetQualifier: 'Porta',
        targetCondition: 'Bom',
        domainAttributes: const <String, dynamic>{
          'inspection.material': 'Madeira',
        },
      );

      item.applySelection(newSel);

      expect(item.macroLocal, 'Rua');
      expect(item.ambiente, 'Fachada');
      expect(item.elemento, 'Porta');
      expect(item.estado, 'Bom');
      expect(item.material, 'Madeira');
    });

    test('applySelection com targetItem null não sobrescreve ambiente', () {
      final item = _buildCapture(ambiente: 'Quarto');
      item.applySelection(FlowSelection.empty);
      // targetItem null → ambiente mantido
      expect(item.ambiente, 'Quarto');
    });

    test('round-trip: selection → applySelection preserva dados', () {
      final capture = OverlayCameraCaptureResult(
        filePath: 'photo.jpg',
        macroLocal: 'Rua',
        ambiente: 'Fachada',
        elemento: 'Porta',
        material: 'Madeira',
        estado: 'Bom',
        capturedAt: DateTime(2026, 1, 1),
        latitude: 0,
        longitude: 0,
        accuracy: 0,
      );

      final item = InspectionReviewEditableCapture.fromCapture(capture);
      final originalSel = item.selection;
      final anotherItem = _buildCapture();
      anotherItem.applySelection(originalSel);

      expect(anotherItem.macroLocal, capture.macroLocal);
      expect(anotherItem.ambiente, capture.ambiente);
      expect(anotherItem.elemento, capture.elemento);
      expect(anotherItem.material, capture.material);
      expect(anotherItem.estado, capture.estado);
    });
  });

  group('InspectionReviewEditableCapture — status recalculation', () {
    test('pending sem elemento/material/estado', () {
      final item = _buildCapture();
      item.recalculateStatus();
      expect(item.status, InspectionReviewPhotoStatus.pending);
    });

    test('suggested quando tem alguma classificação incompleta', () {
      final item = _buildCapture(elemento: 'Piso');
      item.recalculateStatus();
      expect(item.status, InspectionReviewPhotoStatus.suggested);
    });

    test('classified quando todos os 3 campos preenchidos', () {
      final item = _buildCapture(
        elemento: 'Piso',
        material: 'Cerâmico',
        estado: 'Bom',
      );
      item.recalculateStatus();
      expect(item.status, InspectionReviewPhotoStatus.classified);
    });

    test('forceClassified com qualquer classificação marca como classified', () {
      final item = _buildCapture(elemento: 'Piso');
      item.recalculateStatus(forceClassified: true);
      expect(item.status, InspectionReviewPhotoStatus.classified);
    });
  });
}
