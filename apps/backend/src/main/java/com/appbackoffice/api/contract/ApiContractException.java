package com.appbackoffice.api.contract;

import org.springframework.http.HttpStatus;

public class ApiContractException extends RuntimeException {

    private final HttpStatus status;
    private final String code;
    private final ErrorSeverity severity;
    private final String guidance;
    private final String details;

    public ApiContractException(
            HttpStatus status,
            String code,
            String message,
            ErrorSeverity severity,
            String guidance,
            String details
    ) {
        super(message);
        this.status = status;
        this.code = code;
        this.severity = severity;
        this.guidance = guidance;
        this.details = details;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getCode() {
        return code;
    }

    public ErrorSeverity getSeverity() {
        return severity;
    }

    public String getGuidance() {
        return guidance;
    }

    public String getDetails() {
        return details;
    }
}