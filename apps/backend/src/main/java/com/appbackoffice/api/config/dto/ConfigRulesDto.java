package com.appbackoffice.api.config.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ConfigRulesDto(
        Boolean requireBiometric,
        Integer cameraMinPhotos,
        Integer cameraMaxPhotos,
        Boolean enableVoiceCommands,
        String theme,
        String appUpdateChannel
) {
}