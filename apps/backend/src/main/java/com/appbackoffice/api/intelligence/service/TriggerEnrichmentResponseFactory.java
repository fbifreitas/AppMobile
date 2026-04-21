package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.dto.ExecutionPlanResponse;
import com.appbackoffice.api.intelligence.dto.TriggerEnrichmentResponse;
import com.appbackoffice.api.intelligence.entity.CaseEnrichmentRunEntity;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanSnapshotEntity;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import org.springframework.stereotype.Service;

@Service
public class TriggerEnrichmentResponseFactory {

    private final EnrichmentRunLifecycleService enrichmentRunLifecycleService;

    public TriggerEnrichmentResponseFactory(EnrichmentRunLifecycleService enrichmentRunLifecycleService) {
        this.enrichmentRunLifecycleService = enrichmentRunLifecycleService;
    }

    public TriggerEnrichmentResponse create(CaseEnrichmentRunEntity run,
                                            Long caseId,
                                            ResearchProviderResponse providerResponse,
                                            ExecutionPlanSnapshotEntity snapshot,
                                            ExecutionPlanPayload plan) {
        boolean requiresManualReview = plan.requiresManualReview();
        return new TriggerEnrichmentResponse(
                run.getId(),
                caseId,
                run.getStatus(),
                enrichmentRunLifecycleService.isRetryable(run),
                defaultDouble(run.getConfidenceScore()),
                requiresManualReview,
                run.getProviderName(),
                run.getModelName(),
                run.getErrorCode(),
                resolveSummary(run, requiresManualReview),
                run.getCompletedAt(),
                new ExecutionPlanResponse(
                        snapshot.getId(),
                        snapshot.getCaseId(),
                        snapshot.getStatus(),
                        snapshot.getCreatedAt(),
                        snapshot.getPublishedAt(),
                        plan
                )
        );
    }

    private double defaultDouble(Double value) {
        return value == null ? 0.0 : value;
    }

    private String resolveSummary(CaseEnrichmentRunEntity run, boolean requiresManualReview) {
        if (run.getStatus() == com.appbackoffice.api.intelligence.entity.EnrichmentRunStatus.TEMPORARILY_UNAVAILABLE) {
            return "Automatic analysis is temporarily unavailable. Retry in a few minutes or continue with manual review.";
        }
        return requiresManualReview
                ? "Enrichment completed with manual review required."
                : "Enrichment completed successfully.";
    }
}
