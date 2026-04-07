class VoiceUsageEntry {
  final String transcript;
  final String? commandId;
  final String context;
  final DateTime createdAt;
  final bool matched;

  const VoiceUsageEntry({
    required this.transcript,
    required this.context,
    required this.createdAt,
    required this.matched,
    this.commandId,
  });

  Map<String, dynamic> toJson() {
    return {
      'transcript': transcript,
      'commandId': commandId,
      'context': context,
      'createdAt': createdAt.toIso8601String(),
      'matched': matched,
    };
  }

  factory VoiceUsageEntry.fromJson(Map<String, dynamic> json) {
    return VoiceUsageEntry(
      transcript: json['transcript'] as String? ?? '',
      commandId: json['commandId'] as String?,
      context: json['context'] as String? ?? 'unknown',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      matched: json['matched'] as bool? ?? false,
    );
  }
}
