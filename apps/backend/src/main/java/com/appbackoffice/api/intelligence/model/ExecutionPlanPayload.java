package com.appbackoffice.api.intelligence.model;

import java.util.List;

public record ExecutionPlanPayload(
        String planVersion,
        Long caseId,
        String caseNumber,
        String assetType,
        String assetSubtype,
        String providerName,
        double confidenceScore,
        boolean requiresManualReview,
        PropertyProfile propertyProfile,
        Step1Config step1Config,
        Step2Config step2Config,
        CameraConfig cameraConfig,
        List<String> reviewReasons,
        List<String> fieldAlerts,
        Traceability traceability
) {

    public record PropertyProfile(
            String address,
            Double latitude,
            Double longitude,
            String taxonomy,
            String inspectionType,
            String canonicalAssetType,
            String canonicalAssetSubtype,
            List<String> candidateAssetSubtypes,
            String refinedAssetSubtype,
            String propertyStandard,
            List<String> availablePhotoLocations,
            StructuralFacts structuralFacts
    ) {
    }

    public record Step1Config(
            boolean enabled,
            String initialAssetType,
            String initialAssetSubtype,
            List<String> candidateAssetSubtypes,
            String initialContext,
            List<String> availableContexts
    ) {
    }

    public record Step2Config(
            boolean enabled,
            boolean mandatory,
            List<String> requiredEvidence
    ) {
    }

    public record CameraConfig(
            String mode,
            String macroLocation,
            List<String> availableMacroLocations,
            List<String> suggestedPhotoLocations,
            List<CapturePlanItem> capturePlan,
            List<CameraEnvironmentProfile> compositionProfiles
        ) {
    }

    public record CapturePlanItem(
            String macroLocal,
            String environment,
            String element,
            String material,
            String condition,
            boolean required,
            int minPhotos,
            String source,
            List<NormativeBinding> normativeBindings
    ) {
    }

    public record CameraEnvironmentProfile(
            String macroLocal,
            String photoLocation,
            boolean required,
            int minPhotos,
            List<CameraElementProfile> elements,
            String source,
            List<NormativeBinding> normativeBindings
        ) {
    }

    public record CameraElementProfile(
            String element,
            List<String> materials,
            List<String> states
    ) {
    }

    public record StructuralFacts(
            Integer bedroomsCount,
            Integer bathroomsCount,
            Integer suitesCount,
            Integer garageSpotsCount,
            boolean hasKitchen,
            boolean hasLivingRoom,
            boolean hasDiningRoom,
            boolean hasLaundry,
            boolean hasBalcony,
            boolean hasGarage,
            boolean hasPool,
            boolean hasGym,
            boolean hasPartyRoom,
            boolean hasBarbecueArea,
            boolean hasPlayground,
            boolean hasInternalStair,
            boolean hasUpperFloor,
            boolean hasIntermediateFloor
    ) {
    }

    public record NormativeBinding(
            String dimension,
            String title,
            boolean requiredWhenEnabled,
            boolean blockingOnFinalization,
            int minPhotos,
            Integer maxPhotos,
            List<String> acceptedAlternatives
    ) {
    }

    public record Traceability(
            Long sourceRunId,
            String requestStorageKey,
            String responseNormalizedStorageKey,
            List<String> researchLinks
    ) {
    }
}
