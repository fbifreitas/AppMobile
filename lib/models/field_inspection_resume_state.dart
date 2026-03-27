class FieldInspectionResumeState {
  final String jobId;
  final String currentScreen;
  final int currentStep;
  final Map<String, dynamic> data;
  final DateTime savedAt;

  const FieldInspectionResumeState({
    required this.jobId,
    required this.currentScreen,
    required this.currentStep,
    required this.data,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'currentScreen': currentScreen,
      'currentStep': currentStep,
      'data': data,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory FieldInspectionResumeState.fromJson(Map<String, dynamic> json) {
    return FieldInspectionResumeState(
      jobId: json['jobId'] as String? ?? '',
      currentScreen: json['currentScreen'] as String? ?? 'unknown',
      currentStep: json['currentStep'] as int? ?? 0,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
