class ContextualItemInstance {
  final String baseLabel;
  final int instanceIndex;

  const ContextualItemInstance({
    required this.baseLabel,
    required this.instanceIndex,
  });

  String get displayLabel =>
      instanceIndex <= 1 ? baseLabel : '$baseLabel $instanceIndex';
}

class ContextualItemInstanceService {
  const ContextualItemInstanceService();

  static const ContextualItemInstanceService instance =
      ContextualItemInstanceService();

  ContextualItemInstance parse(String? rawLabel) {
    final label = (rawLabel ?? '').trim();
    if (label.isEmpty) {
      return const ContextualItemInstance(baseLabel: '', instanceIndex: 1);
    }

    final match = RegExp(r'^(.*?)(?:\s+(\d+))$').firstMatch(label);
    if (match == null) {
      return ContextualItemInstance(baseLabel: label, instanceIndex: 1);
    }

    final baseLabel = (match.group(1) ?? '').trim();
    final parsedIndex = int.tryParse(match.group(2) ?? '');
    if (baseLabel.isEmpty || parsedIndex == null || parsedIndex <= 1) {
      return ContextualItemInstance(baseLabel: label, instanceIndex: 1);
    }

    return ContextualItemInstance(
      baseLabel: baseLabel,
      instanceIndex: parsedIndex,
    );
  }

  String baseLabelOf(String? rawLabel) => parse(rawLabel).baseLabel;

  String nextDisplayLabel({
    required String selectedLabel,
    required Iterable<String> existingLabels,
  }) {
    final selected = parse(selectedLabel);
    final baseLabel = selected.baseLabel;
    if (baseLabel.isEmpty) {
      return '';
    }

    var maxIndex = 1;
    for (final label in existingLabels) {
      final parsed = parse(label);
      if (_normalize(parsed.baseLabel) != _normalize(baseLabel)) {
        continue;
      }
      if (parsed.instanceIndex > maxIndex) {
        maxIndex = parsed.instanceIndex;
      }
    }

    return ContextualItemInstance(
      baseLabel: baseLabel,
      instanceIndex: maxIndex + 1,
    ).displayLabel;
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
