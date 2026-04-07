class ObservabilityLogEntry {
  final String id;
  final String category;
  final String level;
  final String message;
  final DateTime createdAt;
  final Map<String, String> metadata;

  const ObservabilityLogEntry({
    required this.id,
    required this.category,
    required this.level,
    required this.message,
    required this.createdAt,
    this.metadata = const <String, String>{},
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'category': category,
      'level': level,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ObservabilityLogEntry.fromJson(Map<String, dynamic> json) {
    return ObservabilityLogEntry(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      level: json['level'] as String? ?? 'info',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      metadata: (json['metadata'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          const <String, String>{},
    );
  }
}
