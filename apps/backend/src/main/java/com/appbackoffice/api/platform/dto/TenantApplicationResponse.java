package com.appbackoffice.api.platform.dto;

import java.time.Instant;

public record TenantApplicationResponse(
        String tenantId,
        String appCode,
        String brandName,
        String displayName,
        String applicationId,
        String bundleId,
        String firebaseAppId,
        String distributionChannel,
        String distributionGroup,
        String status,
        Instant updatedAt
) {
}
