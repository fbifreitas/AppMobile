package com.appbackoffice.api.mobile.dto;

import java.util.List;
import java.util.Map;

public record CheckinConfigResponse(
        String version,
        Map<String, Object> step1,
        Map<String, Object> step2,
        List<String> compatibilityNotes
) {
}
