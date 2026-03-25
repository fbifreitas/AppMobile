import 'inspection_template_model.dart';

enum InspectionEnvironmentStatus {
  pendente,
  emAndamento,
  concluido,
  incompleto,
  naoConfigurado,
}

enum EvidenceSource {
  camera,
  gallery,
}

class GeoPointData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime capturedAt;

  const GeoPointData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'capturedAt': capturedAt.toIso8601String(),
    };
  }

  factory GeoPointData.fromMap(Map<String, dynamic> map) {
    return GeoPointData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      capturedAt: DateTime.parse(map['capturedAt'] as String),
    );
  }
}

class PhotoEvidence {
  final String id;
  final String ambienteId;
  final String ambienteNome;
  final String? elementoId;
  final String? elementoNome;
  final String? material;
  final String? estadoConservacao;
  final String? observacao;
  final String filePath;
  final EvidenceSource source;
  final GeoPointData geoPoint;
  final bool isValidForAudit;
  final bool importedFromGallery;

  const PhotoEvidence({
    required this.id,
    required this.ambienteId,
    required this.ambienteNome,
    required this.filePath,
    required this.source,
    required this.geoPoint,
    required this.isValidForAudit,
    required this.importedFromGallery,
    this.elementoId,
    this.elementoNome,
    this.material,
    this.estadoConservacao,
    this.observacao,
  });

  PhotoEvidence copyWith({
    String? ambienteId,
    String? ambienteNome,
    String? elementoId,
    String? elementoNome,
    String? material,
    String? estadoConservacao,
    String? observacao,
    String? filePath,
    EvidenceSource? source,
    GeoPointData? geoPoint,
    bool? isValidForAudit,
    bool? importedFromGallery,
  }) {
    return PhotoEvidence(
      id: id,
      ambienteId: ambienteId ?? this.ambienteId,
      ambienteNome: ambienteNome ?? this.ambienteNome,
      elementoId: elementoId ?? this.elementoId,
      elementoNome: elementoNome ?? this.elementoNome,
      material: material ?? this.material,
      estadoConservacao: estadoConservacao ?? this.estadoConservacao,
      observacao: observacao ?? this.observacao,
      filePath: filePath ?? this.filePath,
      source: source ?? this.source,
      geoPoint: geoPoint ?? this.geoPoint,
      isValidForAudit: isValidForAudit ?? this.isValidForAudit,
      importedFromGallery: importedFromGallery ?? this.importedFromGallery,
    );
  }

  bool get hasElementClassification =>
      elementoId != null && elementoId!.isNotEmpty;

  bool get hasStateClassification =>
      estadoConservacao != null && estadoConservacao!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ambienteId': ambienteId,
      'ambienteNome': ambienteNome,
      'elementoId': elementoId,
      'elementoNome': elementoNome,
      'material': material,
      'estadoConservacao': estadoConservacao,
      'observacao': observacao,
      'filePath': filePath,
      'source': source.name,
      'geoPoint': geoPoint.toMap(),
      'isValidForAudit': isValidForAudit,
      'importedFromGallery': importedFromGallery,
    };
  }

  factory PhotoEvidence.fromMap(Map<String, dynamic> map) {
    return PhotoEvidence(
      id: map['id'] as String,
      ambienteId: map['ambienteId'] as String,
      ambienteNome: map['ambienteNome'] as String,
      elementoId: map['elementoId'] as String?,
      elementoNome: map['elementoNome'] as String?,
      material: map['material'] as String?,
      estadoConservacao: map['estadoConservacao'] as String?,
      observacao: map['observacao'] as String?,
      filePath: map['filePath'] as String,
      source: EvidenceSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => EvidenceSource.camera,
      ),
      geoPoint: GeoPointData.fromMap(
        Map<String, dynamic>.from(map['geoPoint'] as Map),
      ),
      isValidForAudit: map['isValidForAudit'] as bool? ?? true,
      importedFromGallery: map['importedFromGallery'] as bool? ?? false,
    );
  }
}

class InspectionEnvironmentProgress {
  final String ambienteId;
  final String ambienteNome;
  final int minFotos;
  final bool obrigatorio;
  final List<PhotoEvidence> evidencias;
  final InspectionEnvironmentStatus status;
  final bool suggestedAsMissingConfig;
  final String? suggestedEnvironmentName;

  const InspectionEnvironmentProgress({
    required this.ambienteId,
    required this.ambienteNome,
    required this.minFotos,
    required this.obrigatorio,
    required this.evidencias,
    required this.status,
    this.suggestedAsMissingConfig = false,
    this.suggestedEnvironmentName,
  });

  InspectionEnvironmentProgress copyWith({
    String? ambienteId,
    String? ambienteNome,
    int? minFotos,
    bool? obrigatorio,
    List<PhotoEvidence>? evidencias,
    InspectionEnvironmentStatus? status,
    bool? suggestedAsMissingConfig,
    String? suggestedEnvironmentName,
  }) {
    return InspectionEnvironmentProgress(
      ambienteId: ambienteId ?? this.ambienteId,
      ambienteNome: ambienteNome ?? this.ambienteNome,
      minFotos: minFotos ?? this.minFotos,
      obrigatorio: obrigatorio ?? this.obrigatorio,
      evidencias: evidencias ?? this.evidencias,
      status: status ?? this.status,
      suggestedAsMissingConfig:
          suggestedAsMissingConfig ?? this.suggestedAsMissingConfig,
      suggestedEnvironmentName:
          suggestedEnvironmentName ?? this.suggestedEnvironmentName,
    );
  }

  int get totalFotos => evidencias.length;

  bool get minFotosAtingido => totalFotos >= minFotos;

  bool get hasPendingClassification =>
      evidencias.any((item) => !item.hasElementClassification);

  Map<String, dynamic> toMap() {
    return {
      'ambienteId': ambienteId,
      'ambienteNome': ambienteNome,
      'minFotos': minFotos,
      'obrigatorio': obrigatorio,
      'evidencias': evidencias.map((e) => e.toMap()).toList(),
      'status': status.name,
      'suggestedAsMissingConfig': suggestedAsMissingConfig,
      'suggestedEnvironmentName': suggestedEnvironmentName,
    };
  }

  factory InspectionEnvironmentProgress.fromTemplate(
    EnvironmentTemplate template,
  ) {
    return InspectionEnvironmentProgress(
      ambienteId: template.id,
      ambienteNome: template.nome,
      minFotos: template.minFotos,
      obrigatorio: template.obrigatorio,
      evidencias: const [],
      status: InspectionEnvironmentStatus.pendente,
    );
  }
}

class ReviewIssue {
  final String id;
  final String title;
  final String description;
  final String ambienteId;
  final bool blocking;

  const ReviewIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.ambienteId,
    required this.blocking,
  });
}

class InspectionSession {
  final String id;
  final String tipoImovel;
  final String subtipoImovel;
  final DateTime startedAt;
  final GeoPointData checkinGeoPoint;
  final InspectionTemplate template;
  final List<InspectionEnvironmentProgress> ambientes;
  final bool gpsEnabled;
  final bool finalized;

  const InspectionSession({
    required this.id,
    required this.tipoImovel,
    required this.subtipoImovel,
    required this.startedAt,
    required this.checkinGeoPoint,
    required this.template,
    required this.ambientes,
    required this.gpsEnabled,
    this.finalized = false,
  });

  factory InspectionSession.start({
    required String id,
    required String tipoImovel,
    required String subtipoImovel,
    required GeoPointData checkinGeoPoint,
    required InspectionTemplate template,
  }) {
    return InspectionSession(
      id: id,
      tipoImovel: tipoImovel,
      subtipoImovel: subtipoImovel,
      startedAt: DateTime.now(),
      checkinGeoPoint: checkinGeoPoint,
      template: template,
      ambientes: template.ambientes
          .map(InspectionEnvironmentProgress.fromTemplate)
          .toList(),
      gpsEnabled: true,
    );
  }

  InspectionSession copyWith({
    String? id,
    String? tipoImovel,
    String? subtipoImovel,
    DateTime? startedAt,
    GeoPointData? checkinGeoPoint,
    InspectionTemplate? template,
    List<InspectionEnvironmentProgress>? ambientes,
    bool? gpsEnabled,
    bool? finalized,
  }) {
    return InspectionSession(
      id: id ?? this.id,
      tipoImovel: tipoImovel ?? this.tipoImovel,
      subtipoImovel: subtipoImovel ?? this.subtipoImovel,
      startedAt: startedAt ?? this.startedAt,
      checkinGeoPoint: checkinGeoPoint ?? this.checkinGeoPoint,
      template: template ?? this.template,
      ambientes: ambientes ?? this.ambientes,
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
      finalized: finalized ?? this.finalized,
    );
  }

  InspectionEnvironmentProgress? getEnvironment(String ambienteId) {
    try {
      return ambientes.firstWhere((item) => item.ambienteId == ambienteId);
    } catch (_) {
      return null;
    }
  }

  List<PhotoEvidence> get allPhotos =>
      ambientes.expand((item) => item.evidencias).toList();

  int get totalRequiredPhotos {
    return ambientes
        .where((item) => item.obrigatorio)
        .fold<int>(0, (sum, item) => sum + item.minFotos);
  }

  int get totalCapturedPhotos => allPhotos.length;

  double get progressPercent {
    if (totalRequiredPhotos == 0) return 0;
    final ratio = totalCapturedPhotos / totalRequiredPhotos;
    return ratio.clamp(0, 1);
  }

  List<ReviewIssue> buildReviewIssues() {
    final issues = <ReviewIssue>[];

    for (final ambiente in ambientes) {
      if (ambiente.obrigatorio && !ambiente.minFotosAtingido) {
        issues.add(
          ReviewIssue(
            id: 'min_fotos_${ambiente.ambienteId}',
            title: 'Fotos insuficientes',
            description:
                '${ambiente.ambienteNome} precisa de no mínimo ${ambiente.minFotos} foto(s).',
            ambienteId: ambiente.ambienteId,
            blocking: true,
          ),
        );
      }

      for (final element in template
              .getEnvironmentById(ambiente.ambienteId)
              ?.elementos
              .where((e) => e.obrigatorioParaConclusao) ??
          <ElementTemplate>[]) {
        final hasCoverage = ambiente.evidencias.any(
          (e) => e.elementoId == element.id,
        );

        if (ambiente.obrigatorio && !hasCoverage) {
          issues.add(
            ReviewIssue(
              id: 'elemento_${ambiente.ambienteId}_${element.id}',
              title: 'Elemento obrigatório pendente',
              description:
                  '${ambiente.ambienteNome} precisa de evidência para "${element.nome}".',
              ambienteId: ambiente.ambienteId,
              blocking: true,
            ),
          );
        }
      }

      final pendingClassifications = ambiente.evidencias.where(
        (e) => !e.hasElementClassification,
      );

      for (final pending in pendingClassifications) {
        issues.add(
          ReviewIssue(
            id: 'classificacao_${pending.id}',
            title: 'Foto sem classificação',
            description:
                'Há uma foto em ${ambiente.ambienteNome} sem elemento definido.',
            ambienteId: ambiente.ambienteId,
            blocking: false,
          ),
        );
      }
    }

    return issues;
  }

  bool get canFinalize =>
      gpsEnabled && buildReviewIssues().where((i) => i.blocking).isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipoImovel': tipoImovel,
      'subtipoImovel': subtipoImovel,
      'startedAt': startedAt.toIso8601String(),
      'checkinGeoPoint': checkinGeoPoint.toMap(),
      'template': template.toMap(),
      'ambientes': ambientes.map((e) => e.toMap()).toList(),
      'gpsEnabled': gpsEnabled,
      'finalized': finalized,
    };
  }
}