import 'package:flutter/material.dart';

import '../config/checkin_step2_config.dart';
import '../models/checkin_step2_model.dart';
import '../models/overlay_camera_capture_result.dart';
import 'inspection_requirement_policy_service.dart';

class InspectionReviewRequirementStatusData {
  final CheckinStep2PhotoFieldConfig field;
  final bool isDone;

  const InspectionReviewRequirementStatusData({
    required this.field,
    required this.isDone,
  });
}

class InspectionReviewRequirementGroupData {
  final String title;
  final IconData icon;
  final int doneCount;
  final int totalCount;
  final InspectionReviewRequirementStatusData? pendingStatus;
  final List<InspectionReviewRequirementStatusData> statuses;

  const InspectionReviewRequirementGroupData({
    required this.title,
    required this.icon,
    required this.doneCount,
    required this.totalCount,
    required this.pendingStatus,
    required this.statuses,
  });

  bool get isDone => doneCount >= totalCount;
}

class InspectionReviewRequirementService {
  const InspectionReviewRequirementService({
    this.requirementPolicy = InspectionRequirementPolicyService.instance,
  });

  static const InspectionReviewRequirementService instance =
      InspectionReviewRequirementService();

  final InspectionRequirementPolicyService requirementPolicy;

  List<InspectionReviewRequirementStatusData> buildStatuses({
    required List<CheckinStep2PhotoFieldConfig> fields,
    required List<OverlayCameraCaptureResult> captures,
    required CheckinStep2Model persistedModel,
  }) {
    return requirementPolicy
        .evaluateMandatoryFieldStatuses(
          fields: fields,
          captures: captures,
          persistedModel: persistedModel,
        )
        .map(
          (status) => InspectionReviewRequirementStatusData(
            field: status.field,
            isDone: status.isDone,
          ),
        )
        .toList();
  }

  List<InspectionReviewRequirementGroupData> groupStatuses(
    List<InspectionReviewRequirementStatusData> statuses,
  ) {
    final grouped = <String, List<InspectionReviewRequirementStatusData>>{};
    for (final status in statuses) {
      final key = requirementPolicy.normalizeComparableText(status.field.titulo);
      grouped.putIfAbsent(key, () => <InspectionReviewRequirementStatusData>[]).add(status);
    }

    final groups =
        grouped.values.map((items) {
          final doneCount = items.where((item) => item.isDone).length;
          InspectionReviewRequirementStatusData? firstPending;
          for (final item in items) {
            if (!item.isDone) {
              firstPending = item;
              break;
            }
          }
          return InspectionReviewRequirementGroupData(
            title: items.first.field.titulo,
            icon: items.first.field.icon,
            doneCount: doneCount,
            totalCount: items.length,
            pendingStatus: firstPending,
            statuses: items,
          );
        }).toList();

    groups.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      return a.title.compareTo(b.title);
    });
    return groups;
  }
}
