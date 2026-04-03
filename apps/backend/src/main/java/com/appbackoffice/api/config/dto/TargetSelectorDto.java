package com.appbackoffice.api.config.dto;

public record TargetSelectorDto(
        String unitId,
        String roleId,
        String userId,
        String deviceId
) {
}