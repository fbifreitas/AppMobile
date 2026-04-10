package com.appbackoffice.api.platform.dto;

public record TenantPlatformSummaryResponse(
        String tenantId,
        String slug,
        String displayName,
        String tenantStatus,
        TenantApplicationResponse application,
        TenantLicenseResponse license
) {
}
