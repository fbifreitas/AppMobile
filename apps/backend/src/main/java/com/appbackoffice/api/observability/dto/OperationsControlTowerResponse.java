package com.appbackoffice.api.observability.dto;

import java.time.Instant;
import java.util.List;

public record OperationsControlTowerResponse(
        Instant generatedAt,
        Overview overview,
        IntelligenceSummary intelligence,
        List<EndpointMetric> endpointMetrics,
        List<AlertItem> alerts,
        List<RecentEventItem> recentEvents,
        RetentionSummary retention,
        ContinuitySummary continuity
) {
    public record Overview(
            long totalRequests24h,
            long errorRequests24h,
            long retryOrDuplicateCount24h,
            long operationalBacklog,
            long pendingIntake,
            long reportsReadyForSign,
            long pendingConfigApprovals,
            int alertCount
    ) {
    }

    public record EndpointMetric(
            String endpointKey,
            long totalRequests,
            long successCount,
            long warningCount,
            long errorCount,
            long retryCount,
            long p95LatencyMs,
            Integer lastHttpStatus,
            Instant lastSeenAt
    ) {
    }

    public record IntelligenceSummary(
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

    public record AlertItem(
            String code,
            String severity,
            String title,
            String description,
            String endpointKey,
            long metricValue,
            Instant triggeredAt
    ) {
    }

    public record RecentEventItem(
            Instant occurredAt,
            String channel,
            String eventType,
            String endpointKey,
            String outcome,
            Integer httpStatus,
            Long latencyMs,
            String summary,
            String correlationId,
            String traceId,
            String protocolId,
            Long jobId,
            Long processId,
            Long reportId
    ) {
    }

    public record RetentionSummary(
            int retentionDays,
            long trackedEvents,
            long expiringEvents,
            Instant oldestRetainedEventAt,
            Instant lastCleanupAt,
            long lastCleanupDeletedCount
    ) {
    }

    public record ContinuitySummary(
            String status,
            List<ChecklistItem> checklist
    ) {
        public record ChecklistItem(
                String code,
                String status,
                String title,
                String action
        ) {
        }
    }
}
