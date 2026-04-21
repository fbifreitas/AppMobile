package com.appbackoffice.api.intelligence.dto;

import com.appbackoffice.api.intelligence.entity.EnrichmentRunStatus;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanStatus;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.job.entity.CaseStatus;
import com.appbackoffice.api.job.entity.JobStatus;
import com.fasterxml.jackson.databind.JsonNode;

import java.time.Instant;
import java.util.List;

public record ReportBasisResponse(
        Long caseId,
        String caseNumber,
        CaseStatus caseStatus,
        String propertyAddress,
        LatestRun latestRun,
        LatestExecutionPlan latestExecutionPlan,
        LatestJob latestJob,
        LatestReturnArtifact latestReturnArtifact,
        List<FieldEvidence> fieldEvidence
) {

    public record LatestRun(
            Long id,
            EnrichmentRunStatus status,
            boolean retryable,
            long attemptCount,
            Double confidenceScore,
            Instant createdAt,
            Instant completedAt,
            JsonNode facts,
            JsonNode qualityFlags,
            String errorCode,
            String errorMessage
    ) {
    }

    public record LatestExecutionPlan(
            Long snapshotId,
            ExecutionPlanStatus status,
            Instant createdAt,
            Instant publishedAt,
            ExecutionPlanPayload plan
    ) {
    }

    public record LatestJob(
            Long id,
            JobStatus status,
            Long assignedTo,
            Instant deadlineAt,
            Instant createdAt
    ) {
    }

    public record LatestReturnArtifact(
            Long inspectionId,
            Long submissionId,
            Long jobId,
            Long executionPlanSnapshotId,
            String rawStorageKey,
            String normalizedStorageKey,
            JsonNode summary,
            Instant createdAt
    ) {
    }

    public record FieldEvidence(
            Long inspectionId,
            Long jobId,
            String sourceSection,
            String macroLocation,
            String environmentName,
            String elementName,
            boolean required,
            Integer minPhotos,
            Integer capturedPhotos,
            String status,
            JsonNode evidence,
            Instant createdAt
    ) {
    }
}
