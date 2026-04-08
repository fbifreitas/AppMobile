package com.appbackoffice.api.valuation.dto;

import java.time.Instant;
import java.util.List;

public record ReportListResponse(
        int total,
        List<Item> items
) {
    public record Item(
            Long id,
            Long valuationProcessId,
            String tenantId,
            String status,
            String generatedBy,
            String approvedBy,
            Instant createdAt,
            Instant updatedAt
    ) {
    }
}
