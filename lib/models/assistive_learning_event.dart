class AssistiveLearningEvent {
  final String context;
  final String key;
  final String value;
  final DateTime createdAt;
  final int weight;

  const AssistiveLearningEvent({
    required this.context,
    required this.key,
    required this.value,
    required this.createdAt,
    this.weight = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'context': context,
      'key': key,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
      'weight': weight,
    };
  }

  factory AssistiveLearningEvent.fromJson(Map<String, dynamic> json) {
    return AssistiveLearningEvent(
      context: json['context'] as String? ?? 'unknown',
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      weight: json['weight'] as int? ?? 1,
    );
  }
}
