package com.appbackoffice.api.contract;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "ErrorSeverity", enumAsRef = true)
public enum ErrorSeverity {
    ERROR,
    WARNING
}