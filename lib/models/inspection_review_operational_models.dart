import 'technical_rule_result.dart';

enum InspectionReviewPendingActionTarget {
  capture,
  fill,
  editComposition,
  finalization,
}

enum InspectionReviewPendingSource {
  normativeMatrix,
  captureTree,
  technicalRule,
  finalization,
}

class InspectionReviewHeaderData {
  final String supportText;
  final bool hasBlockingPendings;

  const InspectionReviewHeaderData({
    required this.supportText,
    required this.hasBlockingPendings,
  });
}

class InspectionReviewCompositionEntry {
  final String id;
  final String title;
  final List<String> contextTrail;
  final List<String> detailTrail;
  final int evidenceCount;
  final bool classified;

  const InspectionReviewCompositionEntry({
    required this.id,
    required this.title,
    required this.contextTrail,
    required this.detailTrail,
    required this.evidenceCount,
    required this.classified,
  });
}

class InspectionReviewEvidenceEntry {
  final String id;
  final String filePath;
  final List<String> contextTrail;
  final String itemLabel;
  final List<String> qualifiers;
  final bool classified;
  final String capturedAtLabel;

  const InspectionReviewEvidenceEntry({
    required this.id,
    required this.filePath,
    required this.contextTrail,
    required this.itemLabel,
    required this.qualifiers,
    required this.classified,
    required this.capturedAtLabel,
  });
}

class InspectionReviewPendingEntry {
  final String id;
  final String title;
  final String reason;
  final String ctaLabel;
  final InspectionReviewPendingActionTarget target;
  final InspectionReviewPendingSource source;
  final String? subjectContext;
  final String? targetItem;
  final String? targetQualifier;
  final String? filePath;
  final TechnicalRuleResult? technicalRule;

  const InspectionReviewPendingEntry({
    required this.id,
    required this.title,
    required this.reason,
    required this.ctaLabel,
    required this.target,
    required this.source,
    this.subjectContext,
    this.targetItem,
    this.targetQualifier,
    this.filePath,
    this.technicalRule,
  });
}

class InspectionReviewOperationalData {
  final InspectionReviewHeaderData header;
  final List<InspectionReviewCompositionEntry> compositions;
  final List<InspectionReviewEvidenceEntry> evidences;
  final List<InspectionReviewPendingEntry> pendings;
  final bool canFinalize;
  final String? footerBlockingMessage;

  const InspectionReviewOperationalData({
    required this.header,
    required this.compositions,
    required this.evidences,
    required this.pendings,
    required this.canFinalize,
    required this.footerBlockingMessage,
  });
}
