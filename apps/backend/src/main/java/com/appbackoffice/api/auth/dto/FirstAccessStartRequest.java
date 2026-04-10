package com.appbackoffice.api.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record FirstAccessStartRequest(
        @NotBlank String tenantId,
        @NotBlank String cpf,
        @NotNull LocalDate birthDate,
        @NotBlank String identifier
) {
}
