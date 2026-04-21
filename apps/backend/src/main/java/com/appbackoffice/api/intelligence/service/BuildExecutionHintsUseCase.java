package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.entity.CaseEnrichmentRunEntity;
import com.appbackoffice.api.intelligence.model.DerivedOperationalAssetProfile;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.appbackoffice.api.job.entity.InspectionCase;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class BuildExecutionHintsUseCase {

    public ExecutionPlanPayload execute(InspectionCase inspectionCase,
                                        DerivedOperationalAssetProfile derivedProfile,
                                        CaseEnrichmentRunEntity run,
                                        ResearchProviderResponse providerResponse) {
        List<String> fieldAlerts = new ArrayList<>();
        boolean requiresManualReview = providerResponse.requiresManualReview() || derivedProfile.requiresManualReview();
        List<String> availableContexts = derivedProfile.compositionProfiles().stream()
                .map(ExecutionPlanPayload.CameraEnvironmentProfile::macroLocal)
                .filter(value -> value != null && !value.isBlank())
                .distinct()
                .toList();
        if (requiresManualReview) {
            fieldAlerts.add("Manual review required before trusting all generated hints.");
        }
        if (derivedProfile.reviewReasons() != null) {
            fieldAlerts.addAll(derivedProfile.reviewReasons());
        }
        if (providerResponse.qualityFlags() != null) {
            fieldAlerts.addAll(providerResponse.qualityFlags());
        }

        return new ExecutionPlanPayload(
                "v1",
                inspectionCase.getId(),
                inspectionCase.getNumber(),
                derivedProfile.canonicalAssetType(),
                derivedProfile.subtypeResolved() ? derivedProfile.canonicalAssetSubtype() : null,
                providerResponse.providerName(),
                providerResponse.confidenceScore(),
                requiresManualReview,
                new ExecutionPlanPayload.PropertyProfile(
                        inspectionCase.getPropertyAddress(),
                        inspectionCase.getPropertyLatitude(),
                        inspectionCase.getPropertyLongitude(),
                        derivedProfile.taxonomy(),
                        inspectionCase.getInspectionType(),
                        derivedProfile.canonicalAssetType(),
                        derivedProfile.subtypeResolved() ? derivedProfile.canonicalAssetSubtype() : null,
                        derivedProfile.candidateAssetSubtypes(),
                        derivedProfile.subtypeResolved() ? derivedProfile.refinedAssetSubtype() : null,
                        derivedProfile.propertyStandard(),
                        derivedProfile.availablePhotoLocations(),
                        derivedProfile.structuralFacts()
                ),
                new ExecutionPlanPayload.Step1Config(
                        true,
                        derivedProfile.canonicalAssetType(),
                        derivedProfile.subtypeResolved() ? derivedProfile.canonicalAssetSubtype() : null,
                        derivedProfile.candidateAssetSubtypes(),
                        derivedProfile.initialContext(),
                        availableContexts
                ),
                new ExecutionPlanPayload.Step2Config(
                        true,
                        providerResponse.confidenceScore() < 0.8 || requiresManualReview,
                        List.of("front_elevation", "access_point")
                ),
                new ExecutionPlanPayload.CameraConfig(
                        "guided",
                        derivedProfile.initialContext(),
                        availableContexts,
                        derivedProfile.availablePhotoLocations(),
                        derivedProfile.capturePlan(),
                        derivedProfile.compositionProfiles()
                ),
                derivedProfile.reviewReasons() == null ? List.of() : List.copyOf(derivedProfile.reviewReasons()),
                List.copyOf(fieldAlerts),
                new ExecutionPlanPayload.Traceability(
                        run.getId(),
                        defaultString(run.getRequestStorageKey()),
                        defaultString(run.getResponseNormalizedStorageKey()),
                        providerResponse.researchLinks() == null ? List.of() : List.copyOf(providerResponse.researchLinks())
                )
        );
    }

    private String defaultString(String value) {
        return value == null ? "" : value;
    }
}
