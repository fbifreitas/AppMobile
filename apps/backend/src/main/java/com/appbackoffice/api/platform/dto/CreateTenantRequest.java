package com.appbackoffice.api.platform.dto;

public record CreateTenantRequest(
        String tenantId,
        String slug,
        String displayName,
        String status
) {
}
