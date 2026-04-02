package com.appbackoffice.api.contract;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;

@Schema(name = "CanonicalErrorResponse", description = "Envelope canônico de erro para integração web-mobile")
public record CanonicalErrorResponse(
        @Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = "2026-04-01T14:25:33Z") Instant timestamp,
        @Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = "CTX_MISSING_HEADER") String code,
        @Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = "ERROR") ErrorSeverity severity,
        @Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = "X-Correlation-Id é obrigatório") String message,
        @Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = "Informe os cabeçalhos de contexto e tente novamente.") String guidance,
        @Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = "1fd3a4f7-9f59-4db8-b4fb-993f7a5e0e71") String correlationId,
        @Schema(requiredMode = Schema.RequiredMode.REQUIRED, example = "/api/mobile/checkin-config") String path,
        @Schema(example = "header: X-Correlation-Id") String details
) {
}