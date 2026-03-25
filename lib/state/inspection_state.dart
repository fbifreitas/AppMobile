import 'package:flutter/foundation.dart';

import '../models/inspection_session_model.dart';
import '../models/inspection_template_model.dart';
import '../services/inspection_capture_service.dart';
import '../services/inspection_local_storage_service.dart';

class InspectionState extends ChangeNotifier {
  InspectionState({
    InspectionCaptureService? captureService,
    InspectionLocalStorageService? localStorageService,
  })  : _captureService = captureService ?? InspectionCaptureService(),
        _localStorageService =
            localStorageService ?? InspectionLocalStorageService() {
    _restorePersistedSession();
  }

  final InspectionCaptureService _captureService;
  final InspectionLocalStorageService _localStorageService;

  InspectionSession? _session;
  String? _selectedEnvironmentId;
  String _suggestedMissingEnvironmentName = '';
  bool _isRestoring = true;

  InspectionSession? get session => _session;
  String? get selectedEnvironmentId => _selectedEnvironmentId;
  String get suggestedMissingEnvironmentName => _suggestedMissingEnvironmentName;
  bool get isRestoring => _isRestoring;

  bool get hasActiveSession => _session != null;

  List<InspectionEnvironmentProgress> get ambientes =>
      _session?.ambientes ?? const [];

  List<ReviewIssue> get reviewIssues =>
      _session?.buildReviewIssues() ?? const [];

  Future<void> _restorePersistedSession() async {
    try {
      _session = await _localStorageService.loadActiveSession();
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> startMockInspection({
    required String tipoImovel,
    required String subtipoImovel,
  }) async {
    final template = InspectionTemplateFactory.byKey(
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
    );

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
    await _persistSession();
    notifyListeners();
  }

  Future<void> refreshCheckinGeoPoint() async {
    if (_session == null) return;

    final currentGeo = await _captureService.getCurrentGeoPoint();
    _session = _session!.copyWith(
      checkinGeoPoint: currentGeo,
      gpsEnabled: true,
      lastSavedAt: DateTime.now(),
    );
    await _persistSession();
    notifyListeners();
  }

  Future<void> validateGpsStatus() async {
    if (_session == null) return;

    try {
      await _captureService.ensureLocationReady();
      _session = _session!.copyWith(gpsEnabled: true, lastSavedAt: DateTime.now());
    } catch (_) {
      _session = _session!.copyWith(gpsEnabled: false, lastSavedAt: DateTime.now());
    }

    await _persistSession();
    notifyListeners();
  }

  void setGpsEnabled(bool enabled) {
    if (_session == null) return;
    _session = _session!.copyWith(gpsEnabled: enabled, lastSavedAt: DateTime.now());
    _persistSession();
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

  Future<void> registerMissingEnvironmentSuggestion() async {
    if (_session == null || _suggestedMissingEnvironmentName.trim().isEmpty) {
      return;
    }

    final fakeId = 'missing_${DateTime.now().millisecondsSinceEpoch}';

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

    _session = _session!.copyWith(
      ambientes: novosAmbientes,
      lastSavedAt: DateTime.now(),
    );
    _selectedEnvironmentId = fakeId;
    _suggestedMissingEnvironmentName = '';
    await _persistSession();
    notifyListeners();
  }

  InspectionEnvironmentProgress? getSelectedEnvironment() {
    if (_session == null || _selectedEnvironmentId == null) return null;
    return _session!.getEnvironment(_selectedEnvironmentId!);
  }

  Future<void> captureEvidenceFromCamera({
    required String ambienteId,
    String? elementoId,
    String? elementoNome,
    String? material,
    String? estadoConservacao,
  }) async {
    if (_session == null) return;

    final ambiente = _session!.getEnvironment(ambienteId);
    if (ambiente == null) return;

    final evidence = await _captureService.captureCameraEvidence(
      session: _session!,
      ambienteId: ambiente.ambienteId,
      ambienteNome: ambiente.ambienteNome,
      elementoId: elementoId,
      elementoNome: elementoNome,
      material: material,
      estadoConservacao: estadoConservacao,
    );

    await _appendEvidence(ambienteId: ambienteId, evidence: evidence);
  }

  Future<void> captureEvidenceFromGallery({
    required String ambienteId,
    String? elementoId,
    String? elementoNome,
    String? material,
    String? estadoConservacao,
  }) async {
    if (_session == null) return;
    if (!_session!.template.auditRules.galleryAllowed) {
      throw const InspectionCaptureException(
        'A galeria está desabilitada para esta vistoria.',
      );
    }

    final ambiente = _session!.getEnvironment(ambienteId);
    if (ambiente == null) return;

    final evidence = await _captureService.pickGalleryEvidence(
      session: _session!,
      ambienteId: ambiente.ambienteId,
      ambienteNome: ambiente.ambienteNome,
      elementoId: elementoId,
      elementoNome: elementoNome,
      material: material,
      estadoConservacao: estadoConservacao,
    );

    await _appendEvidence(ambienteId: ambienteId, evidence: evidence);
  }

  Future<void> updateEvidenceClassification({
    required String ambienteId,
    required String evidenceId,
    String? elementoId,
    String? elementoNome,
    String? material,
    String? estadoConservacao,
    String? observacao,
  }) async {
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

    _session = _session!.copyWith(
      ambientes: novosAmbientes,
      lastSavedAt: DateTime.now(),
    );
    await _persistSession();
    notifyListeners();
  }

  Future<void> removeEvidence({
    required String ambienteId,
    required String evidenceId,
  }) async {
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

    _session = _session!.copyWith(
      ambientes: novosAmbientes,
      lastSavedAt: DateTime.now(),
    );
    await _persistSession();
    notifyListeners();
  }

  Future<void> markPendingUpload() async {
    if (_session == null) return;

    _session = _session!.copyWith(
      syncStatus: InspectionSyncStatus.pendingUpload,
      finalized: true,
      lastSavedAt: DateTime.now(),
    );

    await _persistSession();
    await _localStorageService.queuePendingUpload(_session!);
    notifyListeners();
  }

  Future<void> markSyncedAndClearActive() async {
    if (_session == null) return;

    final synced = _session!.copyWith(
      syncStatus: InspectionSyncStatus.synced,
      lastSavedAt: DateTime.now(),
      lastSyncedAt: DateTime.now(),
    );

    await _localStorageService.removePendingUpload(synced.id);
    await _localStorageService.clearActiveSession();
    _session = null;
    _selectedEnvironmentId = null;
    notifyListeners();
  }

  Future<void> finalizeInspection() async {
    if (_session == null) return;
    if (!_session!.canFinalize) return;

    _session = _session!.copyWith(
      finalized: true,
      syncStatus: InspectionSyncStatus.pendingUpload,
      lastSavedAt: DateTime.now(),
    );

    await _persistSession();
    await _localStorageService.queuePendingUpload(_session!);
    notifyListeners();
  }

  Future<List<InspectionSession>> loadPendingUploads() {
    return _localStorageService.loadPendingUploads();
  }

  Future<void> discardActiveSession() async {
    _session = null;
    _selectedEnvironmentId = null;
    await _localStorageService.clearActiveSession();
    notifyListeners();
  }

  Future<void> _appendEvidence({
    required String ambienteId,
    required PhotoEvidence evidence,
  }) async {
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

    _session = _session!.copyWith(
      ambientes: novosAmbientes,
      lastSavedAt: DateTime.now(),
      syncStatus: InspectionSyncStatus.draft,
    );
    await _persistSession();
    notifyListeners();
  }

  Future<void> _persistSession() async {
    if (_session == null) return;
    await _localStorageService.saveActiveSession(_session!);
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

    final envTemplate =
        _session?.template.getEnvironmentById(ambiente.ambienteId);

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


