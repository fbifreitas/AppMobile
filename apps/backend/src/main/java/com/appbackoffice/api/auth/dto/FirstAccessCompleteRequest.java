package com.appbackoffice.api.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record FirstAccessCompleteRequest(
        @NotBlank String tenantId,
        @NotBlank String challengeId,
        @NotBlank String otp,
        @NotBlank @Size(min = 8, max = 128) String newPassword,
        String deviceInfo
) {
}
