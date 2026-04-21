package com.appbackoffice.api.intelligence.dto;

import com.appbackoffice.api.intelligence.entity.EnrichmentRunStatus;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanStatus;
import com.appbackoffice.api.job.entity.CaseStatus;
import com.appbackoffice.api.job.entity.JobStatus;

import java.time.Instant;
import java.util.List;

public record ManualResolutionQueueResponse(
        long total,
        List<Item> items
) {

    public record Item(
            Long caseId,
            String caseNumber,
            CaseStatus caseStatus,
            String propertyAddress,
            Long latestRunId,
            EnrichmentRunStatus latestRunStatus,
            boolean retryable,
            long attemptCount,
            Double confidenceScore,
            String latestErrorCode,
            String latestErrorMessage,
            Long executionPlanSnapshotId,
            ExecutionPlanStatus executionPlanStatus,
            Long jobId,
            JobStatus jobStatus,
            List<String> pendingReasons,
            Instant queuedAt
    ) {
    }
}
