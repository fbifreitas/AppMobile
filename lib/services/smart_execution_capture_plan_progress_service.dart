import '../models/overlay_camera_capture_result.dart';
import '../models/smart_execution_plan.dart';

class SmartExecutionCapturePlanProgressService {
  const SmartExecutionCapturePlanProgressService();

  static const SmartExecutionCapturePlanProgressService instance =
      SmartExecutionCapturePlanProgressService();

  SmartExecutionCapturePlanProgress resolve({
    required SmartExecutionPlan? plan,
    required List<OverlayCameraCaptureResult> captures,
  }) {
    if (plan == null || plan.capturePlan.isEmpty) {
      return const SmartExecutionCapturePlanProgress.empty();
    }

    final requiredItems =
        plan.capturePlan.where((item) => item.required).toList(growable: false);
    final relevantItems =
        requiredItems.isEmpty ? plan.capturePlan : requiredItems;

    if (relevantItems.isEmpty) {
      return const SmartExecutionCapturePlanProgress.empty();
    }

    var completedItems = 0;
    SmartExecutionCapturePlanItem? nextPendingItem;

    for (final item in relevantItems) {
      final matchedCaptures =
          captures.where((capture) => _matches(item, capture)).length;
      final minPhotos = item.minPhotos > 0 ? item.minPhotos : 1;
      if (matchedCaptures >= minPhotos) {
        completedItems += 1;
        continue;
      }
      nextPendingItem ??= item;
    }

    return SmartExecutionCapturePlanProgress(
      totalItems: relevantItems.length,
      completedItems: completedItems,
      nextPendingItem: nextPendingItem,
    );
  }

  bool _matches(
    SmartExecutionCapturePlanItem item,
    OverlayCameraCaptureResult capture,
  ) {
    if (!_sameText(item.macroLocal, capture.macroLocal)) {
      return false;
    }
    if (!_sameText(item.environment, capture.ambienteBaseLabel)) {
      return false;
    }

    final itemElement = _normalize(item.element);
    if (itemElement == null) {
      return true;
    }
    return _sameText(itemElement, capture.elemento);
  }

  bool _sameText(String? left, String? right) {
    final normalizedLeft = _normalize(left);
    final normalizedRight = _normalize(right);
    if (normalizedLeft == null) {
      return true;
    }
    return normalizedLeft == normalizedRight;
  }

  String? _normalize(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

class SmartExecutionCapturePlanProgress {
  const SmartExecutionCapturePlanProgress({
    required this.totalItems,
    required this.completedItems,
    required this.nextPendingItem,
  });

  const SmartExecutionCapturePlanProgress.empty()
    : totalItems = 0,
      completedItems = 0,
      nextPendingItem = null;

  final int totalItems;
  final int completedItems;
  final SmartExecutionCapturePlanItem? nextPendingItem;

  bool get hasPlan => totalItems > 0;
}
