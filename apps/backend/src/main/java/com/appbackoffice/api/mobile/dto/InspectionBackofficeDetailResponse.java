package com.appbackoffice.api.mobile.dto;

import com.fasterxml.jackson.databind.JsonNode;

import java.time.Instant;

public record InspectionBackofficeDetailResponse(
        Long id,
        Long submissionId,
        Long jobId,
        String tenantId,
        Long fieldAgentId,
        String idempotencyKey,
        String protocolId,
        String status,
        Instant submittedAt,
        Instant updatedAt,
        JsonNode payload
) {
    public Long vistoriadorId() {
        return fieldAgentId;
    }
}
