package com.appbackoffice.api.mobile.dto;

import java.util.List;
import java.util.Map;

public record CheckinConfigResponse(
        String version,
        String publishedAt,
        List<String> appliedPackageIds,
        Map<String, Object> step1,
        Map<String, Object> step2,
        List<CheckinSectionDto> sections,
        List<String> compatibilityNotes
) {

    public record CheckinSectionDto(
            String key,
            String label,
            boolean mandatory,
            PhotoPolicyDto photos,
            List<String> desiredItems
    ) {
    }

    public record PhotoPolicyDto(
            int min,
            int max
    ) {
    }
}
