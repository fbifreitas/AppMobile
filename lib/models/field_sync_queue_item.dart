import 'field_operation_sync_status.dart';

class FieldSyncQueueItem {
  final String id;
  final String jobId;
  final String actionType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int retryCount;
  final FieldOperationSyncStatus status;
  final String? errorMessage;
  final String? conflictMessage;

  const FieldSyncQueueItem({
    required this.id,
    required this.jobId,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.retryCount = 0,
    this.status = FieldOperationSyncStatus.queued,
    this.errorMessage,
    this.conflictMessage,
  });

  FieldSyncQueueItem copyWith({
    String? id,
    String? jobId,
    String? actionType,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? retryCount,
    FieldOperationSyncStatus? status,
    String? errorMessage,
    String? conflictMessage,
    bool clearErrorMessage = false,
    bool clearConflictMessage = false,
  }) {
    return FieldSyncQueueItem(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      conflictMessage: clearConflictMessage ? null : (conflictMessage ?? this.conflictMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'actionType': actionType,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'retryCount': retryCount,
      'status': status.name,
      'errorMessage': errorMessage,
      'conflictMessage': conflictMessage,
    };
  }

  factory FieldSyncQueueItem.fromJson(Map<String, dynamic> json) {
    return FieldSyncQueueItem(
      id: json['id'] as String? ?? '',
      jobId: json['jobId'] as String? ?? '',
      actionType: json['actionType'] as String? ?? 'unknown',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      retryCount: json['retryCount'] as int? ?? 0,
      status: FieldOperationSyncStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => FieldOperationSyncStatus.queued,
      ),
      errorMessage: json['errorMessage'] as String?,
      conflictMessage: json['conflictMessage'] as String?,
    );
  }
}
