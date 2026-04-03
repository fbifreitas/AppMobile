package com.appbackoffice.api.config.dto;

public record ConfigResolveResponse(
        ConfigResolveInputResponse input,
        ConfigResolveResultResponse result
) {
}