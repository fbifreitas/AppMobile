package com.appbackoffice.api.integration.dto;

import java.time.Instant;

public record DemandResponse(
        String id,
        String externalId,
        String tenantId,
        String status,
        Long caseId,
        Long jobId,
        boolean created,
        Instant createdAt,
        Instant updatedAt
) {
}
