import 'package:flutter/foundation.dart';

import '../models/inspection_session_model.dart';
import '../models/inspection_template_model.dart';

class InspectionState extends ChangeNotifier {
  InspectionSession? _session;
  String? _selectedEnvironmentId;
  String _suggestedMissingEnvironmentName = '';

  InspectionSession? get session => _session;
  String? get selectedEnvironmentId => _selectedEnvironmentId;
  String get suggestedMissingEnvironmentName => _suggestedMissingEnvironmentName;

  bool get hasActiveSession => _session != null;

  List<InspectionEnvironmentProgress> get ambientes =>
      _session?.ambientes ?? const [];

  List<ReviewIssue> get reviewIssues => _session?.buildReviewIssues() ?? const [];

  void startMockInspection({
    required String tipoImovel,
    required String subtipoImovel,
  }) {
    final template = InspectionTemplateFactory.urbanoApartamento();

    _session = InspectionSession.start(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
      checkinGeoPoint: GeoPointData(
        latitude: -23.550520,
        longitude: -46.633308,
        accuracy: 12,
        capturedAt: DateTime.now(),
      ),
      template: template,
    );

    _selectedEnvironmentId = null;
    _suggestedMissingEnvironmentName = '';
    notifyListeners();
  }

  void setGpsEnabled(bool enabled) {
    if (_session == null) return;
    _session = _session!.copyWith(gpsEnabled: enabled);
    notifyListeners();
  }

  void selectEnvironment(String ambienteId) {
    _selectedEnvironmentId = ambienteId;
    notifyListeners();
  }

  void clearSelectedEnvironment() {
    _selectedEnvironmentId = null;
    notifyListeners();
  }

  void setSuggestedMissingEnvironmentName(String value) {
    _suggestedMissingEnvironmentName = value;
    notifyListeners();
  }

  void registerMissingEnvironmentSuggestion() {
    if (_session == null || _suggestedMissingEnvironmentName.trim().isEmpty) {
      return;
    }

    final fakeId =
        'missing_${DateTime.now().millisecondsSinceEpoch.toString()}';

    final novo = InspectionEnvironmentProgress(
      ambienteId: fakeId,
      ambienteNome: _suggestedMissingEnvironmentName.trim(),
      minFotos: 1,
      obrigatorio: false,
      evidencias: const [],
      status: InspectionEnvironmentStatus.naoConfigurado,
      suggestedAsMissingConfig: true,
      suggestedEnvironmentName: _suggestedMissingEnvironmentName.trim(),
    );

    final novosAmbientes = List<InspectionEnvironmentProgress>.from(
      _session!.ambientes,
    )..add(novo);

    _session = _session!.copyWith(ambientes: novosAmbientes);
    _selectedEnvironmentId = fakeId;
    _suggestedMissingEnvironmentName = '';
    notifyListeners();
  }

  InspectionEnvironmentProgress? getSelectedEnvironment() {
    if (_session == null || _selectedEnvironmentId == null) return null;
    return _session!.getEnvironment(_selectedEnvironmentId!);
  }

  void addMockCameraEvidence({
    required String ambienteId,
    String? elementoId,
    String? elementoNome,
    String? material,
    String? estadoConservacao,
  }) {
    if (_session == null) return;
    if (!_session!.gpsEnabled) return;

    final ambiente = _session!.getEnvironment(ambienteId);
    if (ambiente == null) return;

    final evidence = PhotoEvidence(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ambienteId: ambiente.ambienteId,
      ambienteNome: ambiente.ambienteNome,
      elementoId: elementoId,
      elementoNome: elementoNome,
      material: material,
      estadoConservacao: estadoConservacao,
      observacao: null,
      filePath:
          'mock://camera/${ambienteId}/${DateTime.now().millisecondsSinceEpoch}',
      source: EvidenceSource.camera,
      geoPoint: GeoPointData(
        latitude: _session!.checkinGeoPoint.latitude,
        longitude: _session!.checkinGeoPoint.longitude,
        accuracy: 8,
        capturedAt: DateTime.now(),
      ),
      isValidForAudit: true,
      importedFromGallery: false,
    );

    _appendEvidence(ambienteId: ambienteId, evidence: evidence);
  }

  void addMockGalleryEvidence({
    required String ambienteId,
    String? elementoId,
    String? elementoNome,
  }) {
    if (_session == null) return;
    if (!_session!.gpsEnabled) return;
    if (!_session!.template.auditRules.galleryAllowed) return;

    final ambiente = _session!.getEnvironment(ambienteId);
    if (ambiente == null) return;

    final evidence = PhotoEvidence(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ambienteId: ambiente.ambienteId,
      ambienteNome: ambiente.ambienteNome,
      elementoId: elementoId,
      elementoNome: elementoNome,
      material: null,
      estadoConservacao: null,
      observacao: null,
      filePath:
          'mock://gallery/${ambienteId}/${DateTime.now().millisecondsSinceEpoch}',
      source: EvidenceSource.gallery,
      geoPoint: GeoPointData(
        latitude: _session!.checkinGeoPoint.latitude,
        longitude: _session!.checkinGeoPoint.longitude,
        accuracy: 14,
        capturedAt: DateTime.now(),
      ),
      isValidForAudit: true,
      importedFromGallery: true,
    );

    _appendEvidence(ambienteId: ambienteId, evidence: evidence);
  }

  void updateEvidenceClassification({
    required String ambienteId,
    required String evidenceId,
    String? elementoId,
    String? elementoNome,
    String? material,
    String? estadoConservacao,
    String? observacao,
  }) {
    if (_session == null) return;

    final novosAmbientes = _session!.ambientes.map((ambiente) {
      if (ambiente.ambienteId != ambienteId) return ambiente;

      final novasEvidencias = ambiente.evidencias.map((evidence) {
        if (evidence.id != evidenceId) return evidence;

        return evidence.copyWith(
          elementoId: elementoId ?? evidence.elementoId,
          elementoNome: elementoNome ?? evidence.elementoNome,
          material: material ?? evidence.material,
          estadoConservacao: estadoConservacao ?? evidence.estadoConservacao,
          observacao: observacao ?? evidence.observacao,
        );
      }).toList();

      return ambiente.copyWith(
        evidencias: novasEvidencias,
        status: _calculateEnvironmentStatus(
          ambiente.copyWith(evidencias: novasEvidencias),
        ),
      );
    }).toList();

    _session = _session!.copyWith(ambientes: novosAmbientes);
    notifyListeners();
  }

  void removeEvidence({
    required String ambienteId,
    required String evidenceId,
  }) {
    if (_session == null) return;

    final novosAmbientes = _session!.ambientes.map((ambiente) {
      if (ambiente.ambienteId != ambienteId) return ambiente;

      final novasEvidencias = ambiente.evidencias
          .where((e) => e.id != evidenceId)
          .toList();

      return ambiente.copyWith(
        evidencias: novasEvidencias,
        status: _calculateEnvironmentStatus(
          ambiente.copyWith(evidencias: novasEvidencias),
        ),
      );
    }).toList();

    _session = _session!.copyWith(ambientes: novosAmbientes);
    notifyListeners();
  }

  void finalizeInspection() {
    if (_session == null) return;
    if (!_session!.canFinalize) return;

    _session = _session!.copyWith(finalized: true);
    notifyListeners();
  }

  void _appendEvidence({
    required String ambienteId,
    required PhotoEvidence evidence,
  }) {
    final novosAmbientes = _session!.ambientes.map((ambiente) {
      if (ambiente.ambienteId != ambienteId) return ambiente;

      final novasEvidencias = List<PhotoEvidence>.from(ambiente.evidencias)
        ..add(evidence);

      return ambiente.copyWith(
        evidencias: novasEvidencias,
        status: _calculateEnvironmentStatus(
          ambiente.copyWith(evidencias: novasEvidencias),
        ),
      );
    }).toList();

    _session = _session!.copyWith(ambientes: novosAmbientes);
    notifyListeners();
  }

  InspectionEnvironmentStatus _calculateEnvironmentStatus(
    InspectionEnvironmentProgress ambiente,
  ) {
    if (ambiente.suggestedAsMissingConfig) {
      return ambiente.evidencias.isEmpty
          ? InspectionEnvironmentStatus.naoConfigurado
          : InspectionEnvironmentStatus.emAndamento;
    }

    if (ambiente.evidencias.isEmpty) {
      return InspectionEnvironmentStatus.pendente;
    }

    if (!ambiente.minFotosAtingido) {
      return InspectionEnvironmentStatus.emAndamento;
    }

    final envTemplate = _session?.template.getEnvironmentById(ambiente.ambienteId);

    if (envTemplate == null) {
      return InspectionEnvironmentStatus.emAndamento;
    }

    final mandatoryElements = envTemplate.elementos
        .where((e) => e.obrigatorioParaConclusao)
        .toList();

    final allCovered = mandatoryElements.every(
      (element) => ambiente.evidencias.any((e) => e.elementoId == element.id),
    );

    if (allCovered) {
      return InspectionEnvironmentStatus.concluido;
    }

    return InspectionEnvironmentStatus.incompleto;
  }
}