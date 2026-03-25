import '../config/checkin_step2_config.dart';

class CheckinStep2PhotoAnswer {
  final String fieldId;
  final String titulo;
  final String? imagePath;
  final DateTime? capturedAt;

  const CheckinStep2PhotoAnswer({
    required this.fieldId,
    required this.titulo,
    this.imagePath,
    this.capturedAt,
  });

  CheckinStep2PhotoAnswer copyWith({
    String? fieldId,
    String? titulo,
    String? imagePath,
    DateTime? capturedAt,
  }) {
    return CheckinStep2PhotoAnswer(
      fieldId: fieldId ?? this.fieldId,
      titulo: titulo ?? this.titulo,
      imagePath: imagePath ?? this.imagePath,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'fieldId': fieldId,
      'titulo': titulo,
      'imagePath': imagePath,
      'capturedAt': capturedAt?.toIso8601String(),
    };
  }

  factory CheckinStep2PhotoAnswer.fromMap(Map<String, dynamic> map) {
    return CheckinStep2PhotoAnswer(
      fieldId: map['fieldId'] as String,
      titulo: map['titulo'] as String,
      imagePath: map['imagePath'] as String?,
      capturedAt: map['capturedAt'] != null
          ? DateTime.tryParse(map['capturedAt'] as String)
          : null,
    );
  }
}

class CheckinStep2GroupAnswer {
  final String groupId;
  final List<String> selectedOptionIds;
  final String observacao;

  const CheckinStep2GroupAnswer({
    required this.groupId,
    this.selectedOptionIds = const [],
    this.observacao = '',
  });

  CheckinStep2GroupAnswer copyWith({
    String? groupId,
    List<String>? selectedOptionIds,
    String? observacao,
  }) {
    return CheckinStep2GroupAnswer(
      groupId: groupId ?? this.groupId,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      observacao: observacao ?? this.observacao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'selectedOptionIds': selectedOptionIds,
      'observacao': observacao,
    };
  }

  factory CheckinStep2GroupAnswer.fromMap(Map<String, dynamic> map) {
    return CheckinStep2GroupAnswer(
      groupId: map['groupId'] as String,
      selectedOptionIds: List<String>.from(map['selectedOptionIds'] ?? []),
      observacao: map['observacao'] as String? ?? '',
    );
  }
}

class CheckinStep2Model {
  final TipoImovel tipoImovel;
  final Map<String, CheckinStep2PhotoAnswer> fotos;
  final Map<String, CheckinStep2GroupAnswer> respostas;

  const CheckinStep2Model({
    required this.tipoImovel,
    required this.fotos,
    required this.respostas,
  });

  factory CheckinStep2Model.empty(TipoImovel tipoImovel) {
    final config = CheckinStep2Configs.byTipo(tipoImovel);

    final fotos = <String, CheckinStep2PhotoAnswer>{};
    final respostas = <String, CheckinStep2GroupAnswer>{};

    for (final campo in config.camposFotos) {
      fotos[campo.id] = CheckinStep2PhotoAnswer(
        fieldId: campo.id,
        titulo: campo.titulo,
      );
    }

    for (final grupo in config.gruposOpcoes) {
      respostas[grupo.id] = CheckinStep2GroupAnswer(groupId: grupo.id);
    }

    return CheckinStep2Model(
      tipoImovel: tipoImovel,
      fotos: fotos,
      respostas: respostas,
    );
  }

  CheckinStep2Model copyWith({
    TipoImovel? tipoImovel,
    Map<String, CheckinStep2PhotoAnswer>? fotos,
    Map<String, CheckinStep2GroupAnswer>? respostas,
  }) {
    return CheckinStep2Model(
      tipoImovel: tipoImovel ?? this.tipoImovel,
      fotos: fotos ?? this.fotos,
      respostas: respostas ?? this.respostas,
    );
  }

  CheckinStep2Model setPhoto({
    required String fieldId,
    required String titulo,
    required String imagePath,
  }) {
    final novasFotos = Map<String, CheckinStep2PhotoAnswer>.from(fotos);
    novasFotos[fieldId] = CheckinStep2PhotoAnswer(
      fieldId: fieldId,
      titulo: titulo,
      imagePath: imagePath,
      capturedAt: DateTime.now(),
    );

    return copyWith(fotos: novasFotos);
  }

  CheckinStep2Model removePhoto(String fieldId) {
    final novasFotos = Map<String, CheckinStep2PhotoAnswer>.from(fotos);
    final fotoAtual = novasFotos[fieldId];

    if (fotoAtual != null) {
      novasFotos[fieldId] = fotoAtual.copyWith(
        imagePath: '',
        capturedAt: null,
      );
    }

    return copyWith(fotos: novasFotos);
  }

  CheckinStep2Model toggleMultiOption({
    required String groupId,
    required String optionId,
  }) {
    final novasRespostas = Map<String, CheckinStep2GroupAnswer>.from(respostas);
    final atual = novasRespostas[groupId] ?? CheckinStep2GroupAnswer(groupId: groupId);

    final selecionadas = List<String>.from(atual.selectedOptionIds);

    if (selecionadas.contains(optionId)) {
      selecionadas.remove(optionId);
    } else {
      selecionadas.add(optionId);
    }

    novasRespostas[groupId] = atual.copyWith(selectedOptionIds: selecionadas);
    return copyWith(respostas: novasRespostas);
  }

  CheckinStep2Model setSingleOption({
    required String groupId,
    required String optionId,
  }) {
    final novasRespostas = Map<String, CheckinStep2GroupAnswer>.from(respostas);
    final atual = novasRespostas[groupId] ?? CheckinStep2GroupAnswer(groupId: groupId);

    novasRespostas[groupId] = atual.copyWith(
      selectedOptionIds: [optionId],
    );

    return copyWith(respostas: novasRespostas);
  }

  CheckinStep2Model setObservacao({
    required String groupId,
    required String observacao,
  }) {
    final novasRespostas = Map<String, CheckinStep2GroupAnswer>.from(respostas);
    final atual = novasRespostas[groupId] ?? CheckinStep2GroupAnswer(groupId: groupId);

    novasRespostas[groupId] = atual.copyWith(observacao: observacao);
    return copyWith(respostas: novasRespostas);
  }

  bool isPhotoCaptured(String fieldId) {
    final foto = fotos[fieldId];
    return foto != null && foto.hasImage;
  }

  bool isOptionSelected({
    required String groupId,
    required String optionId,
  }) {
    final resposta = respostas[groupId];
    if (resposta == null) return false;
    return resposta.selectedOptionIds.contains(optionId);
  }

  Map<String, dynamic> toMap() {
    return {
      'tipoImovel': tipoImovel.label,
      'fotos': fotos.map((key, value) => MapEntry(key, value.toMap())),
      'respostas': respostas.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  factory CheckinStep2Model.fromMap(Map<String, dynamic> map) {
    final tipo = TipoImovelExtension.fromString(map['tipoImovel'] as String? ?? 'Urbano');

    return CheckinStep2Model(
      tipoImovel: tipo,
      fotos: (map['fotos'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          CheckinStep2PhotoAnswer.fromMap(Map<String, dynamic>.from(value)),
        ),
      ),
      respostas: (map['respostas'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          CheckinStep2GroupAnswer.fromMap(Map<String, dynamic>.from(value)),
        ),
      ),
    );
  }
}