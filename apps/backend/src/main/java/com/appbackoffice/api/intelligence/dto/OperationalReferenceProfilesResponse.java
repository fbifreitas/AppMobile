package com.appbackoffice.api.intelligence.dto;

import java.util.List;

public record OperationalReferenceProfilesResponse(
        int total,
        List<Item> items
) {
    public record Item(
            Long id,
            String tenantId,
            String scopeType,
            String sourceType,
            boolean activeFlag,
            String assetType,
            String assetSubtype,
            String refinedAssetSubtype,
            String propertyStandard,
            String regionState,
            String regionCity,
            String regionDistrict,
            int priorityWeight,
            Double confidenceScore,
            int feedbackCount,
            boolean editable,
            List<String> candidateSubtypes,
            List<String> photoLocations,
            int compositionProfileCount,
            String createdAt,
            String updatedAt
    ) {
    }
}
