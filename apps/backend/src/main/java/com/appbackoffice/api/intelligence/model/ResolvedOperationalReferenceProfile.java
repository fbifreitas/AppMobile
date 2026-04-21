package com.appbackoffice.api.intelligence.model;

import java.util.List;

public record ResolvedOperationalReferenceProfile(
        String source,
        List<String> candidateAssetSubtypes,
        List<String> photoLocations,
        List<ExecutionPlanPayload.CameraEnvironmentProfile> compositionProfiles
) {
}
