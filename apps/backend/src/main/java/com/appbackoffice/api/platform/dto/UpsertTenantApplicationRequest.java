package com.appbackoffice.api.platform.dto;

import jakarta.validation.constraints.NotBlank;

public record UpsertTenantApplicationRequest(
        @NotBlank String appCode,
        @NotBlank String brandName,
        @NotBlank String displayName,
        @NotBlank String applicationId,
        @NotBlank String bundleId,
        String firebaseAppId,
        String distributionChannel,
        String distributionGroup,
        @NotBlank String status
) {
}
