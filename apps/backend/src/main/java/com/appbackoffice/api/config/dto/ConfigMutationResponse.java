package com.appbackoffice.api.config.dto;

public record ConfigMutationResponse(
        String message,
        ConfigMutationResultResponse result
) {
}