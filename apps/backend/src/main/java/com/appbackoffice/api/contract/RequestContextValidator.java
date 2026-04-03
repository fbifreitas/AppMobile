package com.appbackoffice.api.contract;

import org.springframework.http.HttpStatus;
import org.springframework.util.StringUtils;

public final class RequestContextValidator {

    private RequestContextValidator() {
    }

    public static void requireCorrelationId(String correlationId) {
        if (!StringUtils.hasText(correlationId)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CTX_MISSING_HEADER",
                    "X-Correlation-Id é obrigatório",
                    ErrorSeverity.ERROR,
                    "Informe os cabeçalhos de contexto e tente novamente.",
                    "header: X-Correlation-Id"
            );
        }
    }

    public static void requireFullContext(String tenantId, String correlationId, String actorId) {
        if (!StringUtils.hasText(tenantId)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CTX_MISSING_HEADER",
                    "X-Tenant-Id é obrigatório",
                    ErrorSeverity.ERROR,
                    "Informe os cabeçalhos de contexto e tente novamente.",
                    "header: X-Tenant-Id"
            );
        }

        requireCorrelationId(correlationId);

        if (!StringUtils.hasText(actorId)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CTX_MISSING_HEADER",
                    "X-Actor-Id é obrigatório",
                    ErrorSeverity.ERROR,
                    "Informe os cabeçalhos de contexto e tente novamente.",
                    "header: X-Actor-Id"
            );
        }
    }
}