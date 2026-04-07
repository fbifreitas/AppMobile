import 'package:appmobile/models/flow_selection.dart';
import 'package:appmobile/models/inspection_session_model.dart';
import 'package:appmobile/services/inspection_capture_service.dart';
import 'package:appmobile/services/inspection_local_storage_service.dart';
import 'package:appmobile/state/inspection_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryInspectionLocalStorageService extends InspectionLocalStorageService {
  InspectionSession? activeSession;

  @override
  Future<InspectionSession?> loadActiveSession() async => activeSession;

  @override
  Future<void> saveActiveSession(InspectionSession session) async {
    activeSession = session;
  }

  @override
  Future<void> clearActiveSession() async {
    activeSession = null;
  }
}

class _FakeInspectionCaptureService extends InspectionCaptureService {
  String? lastTargetItemId;
  String? lastTargetItemLabel;
  String? lastTargetQualifierId;
  String? lastTargetQualifierLabel;
  String? lastTargetCondition;
  Map<String, dynamic> lastDomainAttributes = const <String, dynamic>{};
  bool galleryCaptureTriggered = false;

  @override
  Future<PhotoEvidence> captureCameraEvidenceForSelection({
    required InspectionSession session,
    required String targetItemId,
    required String targetItemLabel,
    String? targetQualifierId,
    String? targetQualifierLabel,
    String? targetCondition,
    Map<String, dynamic> domainAttributes = const <String, dynamic>{},
  }) async {
    galleryCaptureTriggered = false;
    _registerInvocation(
      targetItemId: targetItemId,
      targetItemLabel: targetItemLabel,
      targetQualifierId: targetQualifierId,
      targetQualifierLabel: targetQualifierLabel,
      targetCondition: targetCondition,
      domainAttributes: domainAttributes,
    );
    return _buildEvidence(
      targetItemId: targetItemId,
      targetItemLabel: targetItemLabel,
      targetQualifierId: targetQualifierId,
      targetQualifierLabel: targetQualifierLabel,
      targetCondition: targetCondition,
      domainAttributes: domainAttributes,
      source: EvidenceSource.camera,
    );
  }

  @override
  Future<PhotoEvidence> pickGalleryEvidenceForSelection({
    required InspectionSession session,
    required String targetItemId,
    required String targetItemLabel,
    String? targetQualifierId,
    String? targetQualifierLabel,
    String? targetCondition,
    Map<String, dynamic> domainAttributes = const <String, dynamic>{},
  }) async {
    galleryCaptureTriggered = true;
    _registerInvocation(
      targetItemId: targetItemId,
      targetItemLabel: targetItemLabel,
      targetQualifierId: targetQualifierId,
      targetQualifierLabel: targetQualifierLabel,
      targetCondition: targetCondition,
      domainAttributes: domainAttributes,
    );
    return _buildEvidence(
      targetItemId: targetItemId,
      targetItemLabel: targetItemLabel,
      targetQualifierId: targetQualifierId,
      targetQualifierLabel: targetQualifierLabel,
      targetCondition: targetCondition,
      domainAttributes: domainAttributes,
      source: EvidenceSource.gallery,
    );
  }

  void _registerInvocation({
    required String targetItemId,
    required String targetItemLabel,
    String? targetQualifierId,
    String? targetQualifierLabel,
    String? targetCondition,
    required Map<String, dynamic> domainAttributes,
  }) {
    lastTargetItemId = targetItemId;
    lastTargetItemLabel = targetItemLabel;
    lastTargetQualifierId = targetQualifierId;
    lastTargetQualifierLabel = targetQualifierLabel;
    lastTargetCondition = targetCondition;
    lastDomainAttributes = Map<String, dynamic>.from(domainAttributes);
  }

  PhotoEvidence _buildEvidence({
    required String targetItemId,
    required String targetItemLabel,
    String? targetQualifierId,
    String? targetQualifierLabel,
    String? targetCondition,
    required Map<String, dynamic> domainAttributes,
    required EvidenceSource source,
  }) {
    return PhotoEvidence(
      id: '${source.name}-${DateTime.now().microsecondsSinceEpoch}',
      ambienteId: targetItemId,
      ambienteNome: targetItemLabel,
      elementoId: targetQualifierId,
      elementoNome: targetQualifierLabel,
      material: domainAttributes['inspection.material'] as String?,
      estadoConservacao: targetCondition,
      filePath: '/tmp/evidence.jpg',
      source: source,
      geoPoint: GeoPointData(
        latitude: -23.55,
        longitude: -46.63,
        accuracy: 5,
        capturedAt: DateTime(2026, 4, 6, 12),
      ),
      isValidForAudit: true,
      importedFromGallery: source == EvidenceSource.gallery,
    );
  }
}

void main() {
  group('InspectionState canonical flow', () {
    late _FakeInspectionCaptureService captureService;
    late InspectionState state;

    setUp(() async {
      captureService = _FakeInspectionCaptureService();
      state = InspectionState(
        captureService: captureService,
        localStorageService: _MemoryInspectionLocalStorageService(),
      );
      await Future<void>.delayed(Duration.zero);
      await state.startMockInspection(
        tipoImovel: 'Urbano',
        subtipoImovel: 'Apartamento',
      );
    });

    test('buildSelectionForTargetItem resolves canonical labels from template', () {
      final selection = state.buildSelectionForTargetItem(
        targetItemId: 'sala',
        targetQualifierId: 'piso',
        targetCondition: 'Bom',
        domainAttributes: const <String, dynamic>{
          'inspection.material': 'Madeira',
        },
      );

      expect(selection.targetItem, 'Sala');
      expect(selection.targetQualifier, 'Piso');
      expect(selection.targetCondition, 'Bom');
      expect(selection.attributeText('inspection.material'), 'Madeira');
    });

    test('captureEvidenceForSelection persists canonical evidence', () async {
      final selection = state.buildSelectionForTargetItem(
        targetItemId: 'sala',
        targetQualifierId: 'piso',
        targetCondition: 'Bom',
        domainAttributes: const <String, dynamic>{
          'inspection.material': 'Madeira',
        },
      );

      await state.captureEvidenceForSelection(
        targetItemId: 'sala',
        selection: selection,
      );

      final ambiente = state.session!.getTargetItem('sala')!;
      final evidence = ambiente.evidencias.single;

      expect(captureService.lastTargetItemId, 'sala');
      expect(captureService.lastTargetItemLabel, 'Sala');
      expect(captureService.lastTargetQualifierId, 'piso');
      expect(captureService.lastTargetQualifierLabel, 'Piso');
      expect(captureService.lastTargetCondition, 'Bom');
      expect(captureService.lastDomainAttributes['inspection.material'], 'Madeira');
      expect(evidence.targetItemLabel, 'Sala');
      expect(evidence.targetQualifierLabel, 'Piso');
      expect(evidence.targetCondition, 'Bom');
      expect(evidence.domainAttributes['inspection.material'], 'Madeira');
    });

    test('updateEvidenceClassificationForSelection rewrites stored evidence canonically', () async {
      await state.captureEvidenceForSelection(
        targetItemId: 'sala',
        selection: state.buildSelectionForTargetItem(
          targetItemId: 'sala',
          targetQualifierId: 'piso',
          targetCondition: 'Bom',
          domainAttributes: const <String, dynamic>{
            'inspection.material': 'Madeira',
          },
        ),
      );

      final originalEvidence = state.session!.getTargetItem('sala')!.evidencias.single;

      await state.updateEvidenceClassificationForSelection(
        targetItemId: 'sala',
        evidenceId: originalEvidence.id,
        selection: const FlowSelection(
          targetItem: 'Sala',
          targetQualifier: 'Paredes',
          targetCondition: 'Regular',
          domainAttributes: <String, dynamic>{
            'inspection.material': 'Pintura',
          },
        ),
        observacao: 'Ajustado em revisão',
      );

      final updatedEvidence = state.session!.getTargetItem('sala')!.evidencias.single;
      expect(updatedEvidence.targetQualifierId, 'paredes');
      expect(updatedEvidence.targetQualifierLabel, 'Paredes');
      expect(updatedEvidence.targetCondition, 'Regular');
      expect(updatedEvidence.domainAttributes['inspection.material'], 'Pintura');
      expect(updatedEvidence.observacao, 'Ajustado em revisão');
    });
  });
}
