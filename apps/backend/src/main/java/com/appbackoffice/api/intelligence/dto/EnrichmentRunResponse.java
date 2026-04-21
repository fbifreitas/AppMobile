package com.appbackoffice.api.intelligence.dto;

import com.appbackoffice.api.intelligence.entity.EnrichmentRunStatus;
import com.fasterxml.jackson.databind.JsonNode;

import java.time.Instant;

public record EnrichmentRunResponse(
        Long runId,
        Long caseId,
        EnrichmentRunStatus status,
        boolean retryable,
        long attemptCount,
        String providerName,
        String modelName,
        double confidenceScore,
        Instant createdAt,
        Instant completedAt,
        JsonNode facts,
        JsonNode qualityFlags,
        String requestStorageKey,
        String responseRawStorageKey,
        String responseNormalizedStorageKey,
        String errorCode,
        String errorMessage
) {
}
