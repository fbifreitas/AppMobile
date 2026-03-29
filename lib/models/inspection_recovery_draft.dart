import 'dart:convert';

class InspectionRecoveryDraft {
  const InspectionRecoveryDraft({
    required this.jobId,
    required this.stageKey,
    required this.stageLabel,
    required this.routeName,
    required this.updatedAtIso,
    this.payload = const {},
  });

  final String jobId;
  final String stageKey;
  final String stageLabel;
  final String routeName;
  final String updatedAtIso;
  final Map<String, dynamic> payload;

  factory InspectionRecoveryDraft.initial({
    required String jobId,
  }) {
    return InspectionRecoveryDraft(
      jobId: jobId,
      stageKey: 'checkin',
      stageLabel: 'Check-in',
      routeName: '/checkin',
      updatedAtIso: DateTime.now().toIso8601String(),
      payload: const {},
    );
  }

  InspectionRecoveryDraft copyWith({
    String? jobId,
    String? stageKey,
    String? stageLabel,
    String? routeName,
    String? updatedAtIso,
    Map<String, dynamic>? payload,
  }) {
    return InspectionRecoveryDraft(
      jobId: jobId ?? this.jobId,
      stageKey: stageKey ?? this.stageKey,
      stageLabel: stageLabel ?? this.stageLabel,
      routeName: routeName ?? this.routeName,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'stageKey': stageKey,
      'stageLabel': stageLabel,
      'routeName': routeName,
      'updatedAtIso': updatedAtIso,
      'payload': payload,
    };
  }

  factory InspectionRecoveryDraft.fromMap(Map<String, dynamic> map) {
    return InspectionRecoveryDraft(
      jobId: map['jobId']?.toString() ?? '',
      stageKey: map['stageKey']?.toString() ?? 'checkin',
      stageLabel: map['stageLabel']?.toString() ?? 'Check-in',
      routeName: map['routeName']?.toString() ?? '/checkin',
      updatedAtIso:
          map['updatedAtIso']?.toString() ?? DateTime.now().toIso8601String(),
      payload: Map<String, dynamic>.from(map['payload'] ?? const {}),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory InspectionRecoveryDraft.fromJson(String source) {
    return InspectionRecoveryDraft.fromMap(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }
}
