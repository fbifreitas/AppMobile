package com.appbackoffice.api.platform.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public record UpsertTenantLicenseRequest(
        @NotBlank String licenseModel,
        @Min(0) int contractedSeats,
        @Min(0) int warningSeats,
        boolean hardLimitEnforced
) {
}
