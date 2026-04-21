package com.appbackoffice.api.intelligence.port;

public record ResearchProviderRequest(
        String tenantId,
        Long caseId,
        String caseNumber,
        String propertyAddress,
        String assetType
) {
}
