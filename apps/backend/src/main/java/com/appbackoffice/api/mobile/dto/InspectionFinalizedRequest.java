package com.appbackoffice.api.mobile.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.util.Map;

public record InspectionFinalizedRequest(
        @NotNull Instant exportedAt,
        @NotNull JobRef job,
        @NotNull Map<String, Object> step1,
        @NotNull Map<String, Object> step2,
        @NotNull Map<String, Object> step2Config,
        @NotNull Map<String, Object> review,
        boolean freeCaptureMode,
        boolean manualClassificationRequired
) {
    public record JobRef(@NotBlank String id, String titulo) {
    }
}
