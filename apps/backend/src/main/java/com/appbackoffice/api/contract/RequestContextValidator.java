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

    public static void requireIdempotencyKey(String idempotencyKey) {
        if (!StringUtils.hasText(idempotencyKey)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "IDEMPOTENCY_KEY_REQUIRED",
                    "X-Idempotency-Key e obrigatorio",
                    ErrorSeverity.ERROR,
                    "Informe X-Idempotency-Key para garantir processamento seguro em retries.",
                    "header: X-Idempotency-Key"
            );
        }
    }

    public static void requireProtectedWriteHeaders(String requestTimestamp, String requestNonce) {
        if (!StringUtils.hasText(requestTimestamp)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "REQUEST_TIMESTAMP_REQUIRED",
                    "X-Request-Timestamp is required",
                    ErrorSeverity.ERROR,
                    "Send X-Request-Timestamp in UTC ISO-8601 format for protected mobile write operations.",
                    "header: X-Request-Timestamp"
            );
        }

        if (!StringUtils.hasText(requestNonce)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "REQUEST_NONCE_REQUIRED",
                    "X-Request-Nonce is required",
                    ErrorSeverity.ERROR,
                    "Send a unique X-Request-Nonce for each protected mobile write operation.",
                    "header: X-Request-Nonce"
            );
        }
    }
}
