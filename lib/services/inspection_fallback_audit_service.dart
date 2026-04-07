import '../config/checkin_step2_config.dart';
import '../models/fallback_audit_report.dart';
import '../models/inspection_recovery_draft.dart';
import 'checkin_dynamic_config_service.dart';

class InspectionFallbackAuditService {
  const InspectionFallbackAuditService();

  FallbackAuditReport build({required InspectionRecoveryDraft? draft}) {
    final checks = <FallbackAuditCheck>[];

    if (draft == null) {
      checks.add(
        const FallbackAuditCheck(
          id: 'draft_absent',
          stage: 'global',
          title: 'Draft de recuperacao inexistente',
          detail: 'Nao ha fluxo em recuperacao no momento.',
          passed: false,
        ),
      );

      return _buildReport(
        stageKey: 'none',
        stageLabel: 'Sem recuperacao',
        routeName: '-',
        checks: checks,
      );
    }

    final payload = Map<String, dynamic>.from(draft.payload);
    final step1 = _mapOrEmpty(payload['step1']);
    final step2 = _mapOrEmpty(payload['step2']);
    final review = _mapOrEmpty(payload['review']);
    final step2ConfigRaw = _mapOrEmpty(payload['step2Config']);

    checks.add(
      FallbackAuditCheck(
        id: 'stage_route_consistency',
        stage: 'global',
        title: 'Consistencia entre etapa e rota',
        detail:
            'Etapa atual: ${draft.stageKey} | Rota atual: ${draft.routeName}',
        passed: _isRouteConsistent(draft.stageKey, draft.routeName),
      ),
    );

    checks.add(
      FallbackAuditCheck(
        id: 'updated_at_valid',
        stage: 'global',
        title: 'Timestamp de atualizacao valido',
        detail: draft.updatedAtIso,
        passed: DateTime.tryParse(draft.updatedAtIso) != null,
      ),
    );

    checks.add(
      FallbackAuditCheck(
        id: 'step1_presence',
        stage: 'checkin_step1',
        title: 'Payload do check-in etapa 1 presente',
        detail: step1.isEmpty ? 'Nao encontrado' : 'Encontrado',
        passed: step1.isNotEmpty,
      ),
    );

    checks.add(
      FallbackAuditCheck(
        id: 'step1_required_fields',
        stage: 'checkin_step1',
        title: 'Campos minimos da etapa 1',
        detail:
            'clientePresente, tipoImovel, subtipoImovel e porOndeComecar devem existir.',
        passed: _hasStep1RequiredFields(step1),
      ),
    );

    checks.add(
      FallbackAuditCheck(
        id: 'step2_presence',
        stage: 'checkin_step2',
        title: 'Payload do check-in etapa 2 presente',
        detail: step2.isEmpty ? 'Nao encontrado' : 'Encontrado',
        passed: step2.isNotEmpty,
      ),
    );

    checks.add(
      FallbackAuditCheck(
        id: 'step2_photos_structure',
        stage: 'checkin_step2',
        title: 'Estrutura de fotos da etapa 2 valida',
        detail:
            'Campo fotos deve existir e ser um mapa de respostas de captura.',
        passed: _mapOrEmpty(step2['fotos']).isNotEmpty,
      ),
    );

    final tipo = TipoImovelExtension.fromString(
      '${step1['tipoImovel'] ?? 'Urbano'}',
    );
    final parsedConfig = CheckinDynamicConfigService.instance
        .resolveStoredStep2Config(
          tipo: tipo,
          inspectionRecoveryPayload: {'step2Config': step2ConfigRaw},
        );

    final pendingMandatory = _pendingMandatoryFields(
      fotos: _mapOrEmpty(step2['fotos']),
      config: parsedConfig,
    );

    checks.add(
      FallbackAuditCheck(
        id: 'step2_mandatory_coverage',
        stage: 'checkin_step2',
        title: 'Cobertura dos obrigatorios da etapa 2',
        detail:
            pendingMandatory.isEmpty
                ? 'Todos obrigatorios atendidos.'
                : 'Pendentes: ${pendingMandatory.join(', ')}',
        passed: pendingMandatory.isEmpty,
      ),
    );

    checks.add(
      FallbackAuditCheck(
        id: 'review_presence',
        stage: 'inspection_review',
        title: 'Payload da revisao final presente',
        detail: review.isEmpty ? 'Nao encontrado' : 'Encontrado',
        passed: review.isNotEmpty,
      ),
    );

    checks.add(
      FallbackAuditCheck(
        id: 'review_capture_list',
        stage: 'inspection_review',
        title: 'Lista de capturas na revisao',
        detail:
            'Review deve conter lista de capturas para retomada da etapa final.',
        passed: review['captures'] is List,
        warning: review.isNotEmpty && review['captures'] is! List,
      ),
    );

    checks.add(
      FallbackAuditCheck(
        id: 'checkpoint_chain',
        stage: 'global',
        title: 'Cadeia de checkpoints por etapa',
        detail:
            'Draft deve ter step1 -> step2 -> review conforme avancar de rota.',
        passed: _hasCheckpointChain(
          routeName: draft.routeName,
          step1: step1,
          step2: step2,
          review: review,
        ),
      ),
    );

    return _buildReport(
      stageKey: draft.stageKey,
      stageLabel: draft.stageLabel,
      routeName: draft.routeName,
      checks: checks,
    );
  }

  FallbackAuditReport _buildReport({
    required String stageKey,
    required String stageLabel,
    required String routeName,
    required List<FallbackAuditCheck> checks,
  }) {
    final failed = checks.where((item) => !item.passed && !item.warning).length;
    final warning = checks.where((item) => item.warning && !item.passed).length;

    return FallbackAuditReport(
      generatedAtIso: DateTime.now().toIso8601String(),
      stageKey: stageKey,
      stageLabel: stageLabel,
      routeName: routeName,
      totalChecks: checks.length,
      failedChecks: failed,
      warningChecks: warning,
      checks: checks,
    );
  }

  bool _hasStep1RequiredFields(Map<String, dynamic> step1) {
    if (step1.isEmpty) return false;
    return step1['clientePresente'] != null &&
        _text(step1['tipoImovel']).isNotEmpty &&
        _text(step1['subtipoImovel']).isNotEmpty &&
        _text(step1['porOndeComecar']).isNotEmpty;
  }

  bool _isRouteConsistent(String stageKey, String routeName) {
    final expected = <String, List<String>>{
      'checkin_step1': <String>['/checkin'],
      'checkin_step2': <String>['/checkin_step2'],
      'inspection_review': <String>['/inspection_review'],
      'checkin': <String>['/checkin'],
    };

    final routes = expected[stageKey];
    if (routes == null) return true;
    return routes.contains(routeName);
  }

  bool _hasCheckpointChain({
    required String routeName,
    required Map<String, dynamic> step1,
    required Map<String, dynamic> step2,
    required Map<String, dynamic> review,
  }) {
    if (routeName == '/checkin') {
      return step1.isNotEmpty;
    }
    if (routeName == '/checkin_step2') {
      return step1.isNotEmpty && step2.isNotEmpty;
    }
    if (routeName == '/inspection_review') {
      return step1.isNotEmpty && step2.isNotEmpty && review.isNotEmpty;
    }
    return true;
  }

  List<String> _pendingMandatoryFields({
    required Map<String, dynamic> fotos,
    required CheckinStep2Config config,
  }) {
    final pending = <String>[];
    for (final field in config.camposFotos.where((item) => item.obrigatorio)) {
      final rawAnswer = _mapOrEmpty(fotos[field.id]);
      final imagePath = _text(rawAnswer['imagePath']);
      if (imagePath.isEmpty) {
        pending.add(field.titulo);
      }
    }
    return pending;
  }

  Map<String, dynamic> _mapOrEmpty(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((key, dynamic item) => MapEntry('$key', item)),
      );
    }
    return const <String, dynamic>{};
  }

  String _text(Object? value) => value == null ? '' : '$value'.trim();
}
