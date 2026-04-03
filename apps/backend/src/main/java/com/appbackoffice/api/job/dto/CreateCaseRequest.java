package com.appbackoffice.api.job.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public record CreateCaseRequest(
        @NotBlank String number,
        @NotBlank String propertyAddress,
        @NotBlank String inspectionType,
        Instant deadline,
        @NotBlank String jobTitle
) {
}
