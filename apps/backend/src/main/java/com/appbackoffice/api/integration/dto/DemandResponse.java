package com.appbackoffice.api.integration.dto;

import java.time.Instant;

public record DemandResponse(
        String id,
        String externalId,
        String tenantId,
        String status,
        boolean created,
        Instant createdAt,
        Instant updatedAt
) {
}
