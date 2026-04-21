package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.observability.OperationalEventRecorder;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class EnrichmentDomainEventPublisher {

    private final OperationalEventRecorder eventRecorder;

    public EnrichmentDomainEventPublisher(OperationalEventRecorder eventRecorder) {
        this.eventRecorder = eventRecorder;
    }

    public void publishTriggered(String tenantId,
                                 String actorId,
                                 String correlationId,
                                 Long caseId,
                                 Long runId,
                                 Long snapshotId,
                                 boolean manualReviewRequired) {
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("caseId", caseId);
        details.put("runId", runId);
        details.put("snapshotId", snapshotId);
        details.put("manualReviewRequired", manualReviewRequired);
        eventRecorder.recordDomainEvent(
                tenantId,
                "BACKOFFICE",
                "CASE_ENRICHMENT_TRIGGERED",
                "backoffice.intelligence.enrichment",
                manualReviewRequired ? "WARNING" : "SUCCESS",
                actorId,
                correlationId,
                null,
                null,
                null,
                null,
                null,
                false,
                "Case enrichment triggered for case " + caseId,
                details
        );
    }
}
