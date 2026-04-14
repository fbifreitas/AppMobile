package com.appbackoffice.api.config.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ConfigRulesDto(
        Boolean requireBiometric,
        Integer cameraMinPhotos,
        Integer cameraMaxPhotos,
        Boolean enableVoiceCommands,
        String theme,
        String appUpdateChannel,
        List<ConfigCheckinSectionRuleDto> checkinSections,
        Map<String, Object> step1,
        Map<String, Object> step2,
        Map<String, Object> camera
) {
    public ConfigRulesDto(
            Boolean requireBiometric,
            Integer cameraMinPhotos,
            Integer cameraMaxPhotos,
            Boolean enableVoiceCommands,
            String theme,
            String appUpdateChannel,
            List<ConfigCheckinSectionRuleDto> checkinSections
    ) {
        this(
                requireBiometric,
                cameraMinPhotos,
                cameraMaxPhotos,
                enableVoiceCommands,
                theme,
                appUpdateChannel,
                checkinSections,
                null,
                null,
                null
        );
    }
}
