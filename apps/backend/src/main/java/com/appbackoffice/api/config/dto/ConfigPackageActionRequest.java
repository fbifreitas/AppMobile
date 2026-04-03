package com.appbackoffice.api.config.dto;

import jakarta.validation.constraints.NotBlank;

public record ConfigPackageActionRequest(
        @NotBlank String packageId,
        @NotBlank String tenantId,
        @NotBlank String actorId,
        @NotBlank String actorRole
) {
}