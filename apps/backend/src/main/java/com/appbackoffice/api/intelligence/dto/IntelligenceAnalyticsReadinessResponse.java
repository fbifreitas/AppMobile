package com.appbackoffice.api.intelligence.dto;

public record IntelligenceAnalyticsReadinessResponse(
        long enrichmentRuns,
        long reviewRequiredRuns,
        long failedRuns,
        long executionPlans,
        long publishedExecutionPlans,
        long reviewRequiredExecutionPlans,
        long inspectionReturnArtifacts,
        long fieldEvidenceRecords,
        long manualResolutionCases,
        long reportBasisCases
) {
}
