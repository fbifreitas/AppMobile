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
        JsonNode payload,
        ReturnArtifact returnArtifact,
        java.util.List<FieldEvidence> fieldEvidence
) {
    public Long vistoriadorId() {
        return fieldAgentId;
    }

    public record ReturnArtifact(
            Long executionPlanSnapshotId,
            String rawStorageKey,
            String normalizedStorageKey,
            JsonNode summary
    ) {
    }

    public record FieldEvidence(
            String sourceSection,
            String macroLocation,
            String environmentName,
            String elementName,
            boolean required,
            Integer minPhotos,
            Integer capturedPhotos,
            String status,
            JsonNode evidence
    ) {
    }
}
