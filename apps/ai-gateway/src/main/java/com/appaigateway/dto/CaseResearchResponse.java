package com.appaigateway.dto;

import java.util.List;

public record CaseResearchResponse(
        String providerName,
        String model,
        String promptVersion,
        List<ResearchFactResponse> facts,
        List<String> researchLinks,
        double confidenceScore,
        boolean requiresManualReview,
        List<String> qualityFlags
) {
}
