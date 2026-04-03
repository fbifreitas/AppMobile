package com.appbackoffice.api.config.dto;

public record ConfigAuditEntryResponse(
        String id,
        String packageId,
        String actorId,
        String actorRole,
        String action,
        String tenantId,
        String scope,
        String createdAt
) {
}