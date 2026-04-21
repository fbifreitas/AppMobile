package com.appbackoffice.api.intelligence.entity;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.util.List;

public record OperationalReferenceProfileMutationRequest(
        @NotNull OperationalReferenceScope scopeType,
        boolean activeFlag,
        @NotBlank String assetType,
        @NotBlank String assetSubtype,
        String refinedAssetSubtype,
        String propertyStandard,
        String regionState,
        String regionCity,
        String regionDistrict,
        Integer priorityWeight,
        Double confidenceScore,
        List<String> candidateSubtypes,
        @NotEmpty List<String> photoLocations
) {
}
