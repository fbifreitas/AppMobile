package com.appbackoffice.api.config.dto;

public record ConfigResolveInputResponse(
        String tenantId,
        String unitId,
        String roleId,
        String userId,
        String deviceId
) {
}