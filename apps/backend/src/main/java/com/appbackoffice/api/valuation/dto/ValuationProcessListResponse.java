package com.appbackoffice.api.valuation.dto;

import java.time.Instant;
import java.util.List;

public record ValuationProcessListResponse(
        int total,
        List<Item> items
) {
    public record Item(
            Long id,
            Long inspectionId,
            String tenantId,
            String status,
            String method,
            Long assignedAnalystId,
            Long reportId,
            Instant createdAt,
            Instant updatedAt
    ) {
    }
}
