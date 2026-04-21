import '../l10n/app_strings.dart';
import '../models/overlay_camera_capture_result.dart';
import '../models/smart_execution_plan.dart';
import 'smart_execution_capture_plan_progress_service.dart';

class SmartExecutionPlanGuidancePresenter {
  const SmartExecutionPlanGuidancePresenter({
    this.capturePlanProgressService =
        SmartExecutionCapturePlanProgressService.instance,
  });

  static const SmartExecutionPlanGuidancePresenter instance =
      SmartExecutionPlanGuidancePresenter();

  final SmartExecutionCapturePlanProgressService capturePlanProgressService;

  SmartExecutionPlanGuidance? resolve({
    required SmartExecutionPlan? plan,
    required AppStrings strings,
  }) {
    if (plan == null) {
      return null;
    }

    final items = <String>[];
    final startPoint = _resolveStartPoint(plan, strings);
    if (startPoint != null) {
      items.add(startPoint);
    }
    final classification = _resolveClassification(plan, strings);
    if (classification != null) {
      items.add(classification);
    }
    final composition = _resolveComposition(plan, strings);
    if (composition != null) {
      items.add(composition);
    }
    if (plan.requiredEvidenceCount > 0) {
      items.add(strings.smartGuidanceEvidenceCount(plan.requiredEvidenceCount));
    }
    if (plan.requiresManualReview) {
      items.add(strings.smartGuidanceManualReview);
    }

    if (items.isEmpty) {
      return null;
    }

    return SmartExecutionPlanGuidance(
      title: strings.smartGuidanceTitle,
      items: items,
      requiresAttention: plan.requiresManualReview,
    );
  }

  String? _resolveClassification(
    SmartExecutionPlan plan,
    AppStrings strings,
  ) {
    final assetType = _normalizeText(plan.initialAssetType);
    final assetSubtype =
        _normalizeText(plan.initialAssetSubtype) ??
        _normalizeText(plan.refinedAssetSubtype);
    if (assetType == null && assetSubtype == null) {
      return null;
    }
    final candidateSubtypes =
        plan.candidateAssetSubtypes
            .map((item) => _normalizeText(item))
            .whereType<String>()
            .where((item) => item != assetSubtype)
            .toList(growable: false);
    if (assetType != null && assetSubtype != null) {
      final base = strings.tr(
        'Classificacao sugerida: $assetType > $assetSubtype',
        'Suggested classification: $assetType > $assetSubtype',
      );
      if (candidateSubtypes.isEmpty) {
        return base;
      }
      return strings.tr(
        '$base. Alternativas: ${candidateSubtypes.join(', ')}',
        '$base. Alternatives: ${candidateSubtypes.join(', ')}',
      );
    }
    return strings.tr(
      'Classificacao sugerida: ${assetType ?? assetSubtype}',
      'Suggested classification: ${assetType ?? assetSubtype}',
    );
  }

  String? _resolveComposition(
    SmartExecutionPlan plan,
    AppStrings strings,
  ) {
    if (plan.suggestedPhotoLocations.isEmpty) {
      return null;
    }
    final preview = plan.suggestedPhotoLocations.take(4).join(', ');
    final suffix =
        plan.suggestedPhotoLocations.length > 4
            ? strings.tr(' e mais.', ' and more.')
            : '.';
    return strings.tr(
      'Composicao sugerida para captura: $preview$suffix',
      'Suggested capture composition: $preview$suffix',
    );
  }

  String? resolveCaptureHint({
    required SmartExecutionPlan? plan,
    required AppStrings strings,
    List<OverlayCameraCaptureResult> captures =
        const <OverlayCameraCaptureResult>[],
  }) {
    if (plan == null) {
      return null;
    }

    final progress = capturePlanProgressService.resolve(
      plan: plan,
      captures: captures,
    );
    final captureItem = progress.nextPendingItem ?? plan.firstRequiredCapturePlanItem;
    if (captureItem == null) {
      final guidance = resolve(plan: plan, strings: strings);
      if (guidance == null) {
        return null;
      }
      return '${guidance.title}: ${guidance.items.join(' ')}';
    }

    final parts = <String>[];
    final macroLocal = _displayContext(captureItem.macroLocal, strings);
    final environment = _normalizeText(captureItem.environment);
    final element = _normalizeText(captureItem.element);

    if (macroLocal != null) {
      parts.add(macroLocal);
    }
    if (environment != null) {
      parts.add(environment);
    }
    if (element != null) {
      parts.add(element);
    }

    if (parts.isEmpty) {
      return null;
    }

    final route = parts.join(' > ');
    final minPhotos =
        captureItem.minPhotos > 0
            ? strings.smartGuidanceMinimumPhotos(captureItem.minPhotos)
            : null;
    final sequenceProgress =
        progress.hasPlan
            ? strings.smartCaptureSequenceProgress(
              progress.completedItems,
              progress.totalItems,
            )
            : null;
    final manualReview =
        plan.requiresManualReview ? strings.smartGuidanceManualReview : null;
    final segments = <String>[
      strings.smartCaptureHintRoute(route),
      if (sequenceProgress != null) sequenceProgress,
      if (minPhotos != null) minPhotos,
      if (manualReview != null) manualReview,
    ];

    return '${strings.smartGuidanceTitle}: ${segments.join(' ')}';
  }

  String? _resolveStartPoint(
    SmartExecutionPlan plan,
    AppStrings strings,
  ) {
    final context = _displayContext(plan.initialContext, strings);
    final environment = _normalizeText(plan.firstEnvironment);

    if (context == null && environment == null) {
      return null;
    }

    if (context != null && environment != null) {
      return strings.smartGuidanceStartPointWithEnvironment(
        context,
        environment,
      );
    }

    if (context != null) {
      return strings.smartGuidanceStartPoint(context);
    }

    return strings.smartGuidanceEnvironment(environment!);
  }

  String? _normalizeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String? _displayContext(String? value, AppStrings strings) {
    final normalized = _normalizeText(value);
    if (normalized == null) {
      return null;
    }

    switch (normalized.toLowerCase()) {
      case 'street':
        return strings.tr('Rua', 'Street');
      case 'external area':
        return strings.tr('Área externa', 'External area');
      case 'internal area':
        return strings.tr('Área interna', 'Internal area');
      default:
        return normalized;
    }
  }
}

class SmartExecutionPlanGuidance {
  const SmartExecutionPlanGuidance({
    required this.title,
    required this.items,
    required this.requiresAttention,
  });

  final String title;
  final List<String> items;
  final bool requiresAttention;
}
