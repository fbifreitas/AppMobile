package com.appbackoffice.api.job.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public record CreateCaseRequest(
        @NotBlank String number,
        @NotBlank String propertyAddress,
        @NotBlank String inspectionType,
        Double propertyLatitude,
        Double propertyLongitude,
        Instant deadline,
        @NotBlank String jobTitle
) {
    public CreateCaseRequest(
            String number,
            String propertyAddress,
            String inspectionType,
            Instant deadline,
            String jobTitle
    ) {
        this(number, propertyAddress, inspectionType, null, null, deadline, jobTitle);
    }
}
