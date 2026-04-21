package com.appbackoffice.api.intelligence.dto;

public record OperationalReferenceRebuildResponse(
        String tenantId,
        int rebuiltHistoricalProfiles,
        int rebuiltRegionalProfiles,
        int totalProfilesAfterRebuild,
        String generatedAt
) {
}
