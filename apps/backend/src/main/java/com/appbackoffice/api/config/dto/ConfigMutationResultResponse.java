package com.appbackoffice.api.config.dto;

public record ConfigMutationResultResponse(
        ConfigPackageResponse created,
        ConfigPackageResponse updated
) {
}
