package com.appbackoffice.api.intelligence.model;

import java.util.List;

public record DerivedOperationalAssetProfile(
        String canonicalAssetType,
        String canonicalAssetSubtype,
        List<String> candidateAssetSubtypes,
        String refinedAssetSubtype,
        String propertyStandard,
        String taxonomy,
        String initialContext,
        boolean requiresManualReview,
        boolean subtypeResolved,
        List<String> reviewReasons,
        ExecutionPlanPayload.StructuralFacts structuralFacts,
        List<String> availablePhotoLocations,
        List<ExecutionPlanPayload.CapturePlanItem> capturePlan,
        List<ExecutionPlanPayload.CameraEnvironmentProfile> compositionProfiles
) {
}
