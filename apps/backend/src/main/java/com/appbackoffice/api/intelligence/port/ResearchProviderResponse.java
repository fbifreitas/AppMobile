package com.appbackoffice.api.intelligence.port;

import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;

public record ResearchProviderResponse(
        String providerName,
        String modelName,
        String promptVersion,
        List<ResearchFact> facts,
        List<String> researchLinks,
        JsonNode rawPayload,
        JsonNode normalizedPayload,
        double confidenceScore,
        boolean requiresManualReview,
        List<String> qualityFlags
) {
}
