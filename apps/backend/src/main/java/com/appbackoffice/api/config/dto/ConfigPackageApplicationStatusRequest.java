package com.appbackoffice.api.config.dto;

import jakarta.validation.constraints.NotBlank;

public record ConfigPackageApplicationStatusRequest(
        String packageId,
        @NotBlank String packageVersion,
        String deviceId,
        String appVersion,
        String platform,
        @NotBlank String status,
        String message
) {
}
