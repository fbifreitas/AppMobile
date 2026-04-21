package com.appbackoffice.api.intelligence.dto;

import com.appbackoffice.api.intelligence.entity.EnrichmentRunStatus;

import java.time.Instant;

public record TriggerEnrichmentResponse(
        Long runId,
        Long caseId,
        EnrichmentRunStatus status,
        boolean retryable,
        double confidenceScore,
        boolean manualReviewRequired,
        String providerName,
        String modelName,
        String errorCode,
        String summary,
        Instant completedAt,
        ExecutionPlanResponse executionPlan
) {
}
