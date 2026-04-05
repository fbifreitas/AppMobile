package com.appbackoffice.api.contract;

import org.springframework.http.HttpStatus;
import org.springframework.util.StringUtils;

public final class RequestContextValidator {

    private RequestContextValidator() {
    }

    public static void requireApiVersion(String apiVersion) {
        if (!StringUtils.hasText(apiVersion)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CONTRACT_VERSION_REQUIRED",
                    "X-Api-Version e obrigatorio",
                    ErrorSeverity.ERROR,
                    "Informe X-Api-Version com o contrato suportado pelo backend.",
                    "supported=v1"
            );
        }

        if (!"v1".equalsIgnoreCase(apiVersion.trim())) {
            throw new ApiContractException(
                    HttpStatus.PRECONDITION_FAILED,
                    "CONTRACT_VERSION_UNSUPPORTED",
                    "Versao de contrato mobile nao suportada",
                    ErrorSeverity.ERROR,
                    "Atualize o app para uma versao compativel com o contrato atual.",
                    "supported=v1, received=" + apiVersion
            );
        }
    }

    public static void requireCorrelationId(String correlationId) {
        if (!StringUtils.hasText(correlationId)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CTX_MISSING_HEADER",
                    "X-Correlation-Id e obrigatorio",
                    ErrorSeverity.ERROR,
                    "Informe os cabecalhos de contexto e tente novamente.",
                    "header: X-Correlation-Id"
            );
        }
    }

    public static void requireFullContext(String tenantId, String correlationId, String actorId) {
        if (!StringUtils.hasText(tenantId)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CTX_MISSING_HEADER",
                    "X-Tenant-Id e obrigatorio",
                    ErrorSeverity.ERROR,
                    "Informe os cabecalhos de contexto e tente novamente.",
                    "header: X-Tenant-Id"
            );
        }

        requireCorrelationId(correlationId);

        if (!StringUtils.hasText(actorId)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CTX_MISSING_HEADER",
                    "X-Actor-Id e obrigatorio",
                    ErrorSeverity.ERROR,
                    "Informe os cabecalhos de contexto e tente novamente.",
                    "header: X-Actor-Id"
            );
        }
    }
}
