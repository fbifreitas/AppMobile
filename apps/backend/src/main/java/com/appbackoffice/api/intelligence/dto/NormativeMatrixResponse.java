package com.appbackoffice.api.intelligence.dto;

import java.util.List;

public record NormativeMatrixResponse(
        String tenantId,
        String matrixVersion,
        List<Profile> profiles
) {
    public record Profile(
            String assetType,
            String assetSubtype,
            String refinedAssetSubtype,
            List<RuleItem> rules
    ) {
    }

    public record RuleItem(
            String dimension,
            String title,
            boolean required,
            int minPhotos,
            Integer maxPhotos,
            String blockingStage,
            boolean justificationAllowed,
            List<String> acceptedAlternatives
    ) {
    }
}
