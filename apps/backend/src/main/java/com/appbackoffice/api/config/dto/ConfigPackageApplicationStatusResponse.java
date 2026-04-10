package com.appbackoffice.api.config.dto;

public record ConfigPackageApplicationStatusResponse(
        Long id,
        String tenantId,
        String packageId,
        String packageVersion,
        String actorId,
        String deviceId,
        String appVersion,
        String platform,
        String status,
        String message,
        String appliedAt,
        String updatedAt
) {
}
