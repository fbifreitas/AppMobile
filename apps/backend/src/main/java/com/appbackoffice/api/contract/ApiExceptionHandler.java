package com.appbackoffice.api.contract;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.stream.Collectors;

@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(ApiContractException.class)
    public ResponseEntity<CanonicalErrorResponse> handleApiContractException(
            ApiContractException exception,
            HttpServletRequest request
    ) {
        return build(
                exception.getStatus(),
                exception.getCode(),
                exception.getSeverity(),
                exception.getMessage(),
                exception.getGuidance(),
                request,
                exception.getDetails()
        );
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<CanonicalErrorResponse> handleValidationException(
            MethodArgumentNotValidException exception,
            HttpServletRequest request
    ) {
        String details = exception.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(this::formatFieldError)
                .collect(Collectors.joining("; "));
        return build(
                HttpStatus.BAD_REQUEST,
                "REQ_VALIDATION_FAILED",
                ErrorSeverity.ERROR,
                "Payload inválido",
                "Revise os campos obrigatórios e os formatos do payload.",
                request,
                details
        );
    }

    @ExceptionHandler(MissingRequestHeaderException.class)
    public ResponseEntity<CanonicalErrorResponse> handleMissingRequestHeaderException(
            MissingRequestHeaderException exception,
            HttpServletRequest request
    ) {
        String headerName = exception.getHeaderName();
        String code = "REQ_MISSING_HEADER";
        String guidance = "Informe o cabeçalho obrigatório e tente novamente.";

        if ("X-Idempotency-Key".equalsIgnoreCase(headerName)) {
            code = "IDEMPOTENCY_KEY_REQUIRED";
            guidance = "Informe X-Idempotency-Key para garantir processamento seguro em retries.";
        } else if (
                "X-Tenant-Id".equalsIgnoreCase(headerName)
                        || "X-Correlation-Id".equalsIgnoreCase(headerName)
                        || "X-Actor-Id".equalsIgnoreCase(headerName)
        ) {
            code = "CTX_MISSING_HEADER";
            guidance = "Informe os cabeçalhos de contexto e tente novamente.";
        }

        return build(
                HttpStatus.BAD_REQUEST,
                code,
                ErrorSeverity.ERROR,
                headerName + " é obrigatório",
                guidance,
                request,
                "header: " + headerName
        );
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<CanonicalErrorResponse> handleResponseStatusException(
            ResponseStatusException exception,
            HttpServletRequest request
    ) {
        HttpStatusCode statusCode = exception.getStatusCode();
        HttpStatus status = statusCode instanceof HttpStatus httpStatus ? httpStatus : HttpStatus.BAD_REQUEST;
        String message = StringUtils.hasText(exception.getReason()) ? exception.getReason() : "Erro na requisição";
        return build(
                status,
                "REQ_ERROR",
                ErrorSeverity.ERROR,
                message,
                "Revise os dados enviados e tente novamente.",
                request,
                null
        );
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<CanonicalErrorResponse> handleUnexpectedException(
            Exception exception,
            HttpServletRequest request
    ) {
        return build(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "INTERNAL_UNEXPECTED_ERROR",
                ErrorSeverity.ERROR,
                "Erro interno inesperado",
                "Tente novamente e, se o erro persistir, acione o suporte com o correlationId.",
                request,
                null
        );
    }

    private ResponseEntity<CanonicalErrorResponse> build(
            HttpStatus status,
            String code,
            ErrorSeverity severity,
            String message,
            String guidance,
            HttpServletRequest request,
            String details
    ) {
        CanonicalErrorResponse payload = new CanonicalErrorResponse(
                Instant.now(),
                code,
                severity,
                message,
                guidance,
                request.getHeader("X-Correlation-Id"),
                request.getRequestURI(),
                details
        );
        return ResponseEntity.status(status).body(payload);
    }

    private String formatFieldError(FieldError fieldError) {
        String message = fieldError.getDefaultMessage();
        if (!StringUtils.hasText(message)) {
            message = "valor inválido";
        }
        return fieldError.getField() + ": " + message;
    }
}