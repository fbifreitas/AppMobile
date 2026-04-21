package com.appaigateway.dto;

import jakarta.validation.constraints.NotBlank;

public record CaseResearchRequest(
        @NotBlank String tenantId,
        @NotBlank String caseId,
        @NotBlank String caseNumber,
        @NotBlank String propertyAddress,
        @NotBlank String assetType,
        String model
) {
}
