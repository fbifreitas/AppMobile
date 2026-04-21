package com.appbackoffice.api.mobile.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.Map;

public record InspectionManualClassificationRequest(
        @NotNull @Valid List<CaptureClassification> captures,
        Map<String, Object> step2
) {
    public record CaptureClassification(
            @NotNull String filePath,
            String macroLocation,
            @NotNull String environmentName,
            String elementName,
            String material,
            String state
    ) {
    }
}
