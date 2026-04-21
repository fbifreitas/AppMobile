package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.observability.OperationalEventRecorder;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class MobileExecutionReturnDomainEventPublisher {

    private final OperationalEventRecorder operationalEventRecorder;

    public MobileExecutionReturnDomainEventPublisher(OperationalEventRecorder operationalEventRecorder) {
        this.operationalEventRecorder = operationalEventRecorder;
    }

    public void publishStored(String tenantId,
                              String actorId,
                              String correlationId,
                              String traceId,
                              String protocolId,
                              Long inspectionId,
                              Long submissionId,
                              Long caseId,
                              Long jobId,
                              Long executionPlanSnapshotId,
                              int evidenceCount) {
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("inspectionId", inspectionId);
        details.put("submissionId", submissionId);
        details.put("caseId", caseId);
        details.put("jobId", jobId);
        details.put("executionPlanSnapshotId", executionPlanSnapshotId);
        details.put("evidenceCount", evidenceCount);

        operationalEventRecorder.recordDomainEvent(
                tenantId,
                "MOBILE",
                "INSPECTION_RETURN_STORED",
                "mobile.inspection-return",
                "SUCCESS",
                actorId,
                correlationId,
                traceId,
                protocolId,
                jobId,
                inspectionId,
                null,
                false,
                "Mobile inspection return stored for case " + caseId,
                details
        );
    }
}
