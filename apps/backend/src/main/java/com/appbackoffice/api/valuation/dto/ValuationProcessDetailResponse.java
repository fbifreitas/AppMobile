package com.appbackoffice.api.valuation.dto;

import com.fasterxml.jackson.databind.JsonNode;

import java.time.Instant;

public record ValuationProcessDetailResponse(
        Long id,
        Long inspectionId,
        String tenantId,
        String status,
        String method,
        Long assignedAnalystId,
        Long reportId,
        Instant createdAt,
        Instant updatedAt,
        IntakeValidationSummary latestIntakeValidation
) {
    public record IntakeValidationSummary(
            String result,
            Long validatedBy,
            Instant validatedAt,
            String notes,
            JsonNode issues
    ) {
    }
}
