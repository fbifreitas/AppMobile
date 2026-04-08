package com.appbackoffice.api.valuation.dto;

import com.fasterxml.jackson.databind.JsonNode;

import java.time.Instant;

public record ReportDetailResponse(
        Long id,
        Long valuationProcessId,
        String tenantId,
        String status,
        String generatedBy,
        String approvedBy,
        String reviewNotes,
        Instant createdAt,
        Instant updatedAt,
        JsonNode content
) {
}
