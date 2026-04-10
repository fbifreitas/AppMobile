package com.appbackoffice.api.platform.dto;

public record TenantLicenseResponse(
        String tenantId,
        String licenseModel,
        int contractedSeats,
        int warningSeats,
        boolean hardLimitEnforced,
        long consumedSeats,
        long availableSeats,
        boolean overLimit
) {
}
