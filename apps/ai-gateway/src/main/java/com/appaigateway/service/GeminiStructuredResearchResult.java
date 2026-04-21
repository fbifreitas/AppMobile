package com.appaigateway.service;

import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;

public record GeminiStructuredResearchResult(
        JsonNode structuredPayload,
        List<String> researchLinks,
        List<String> webSearchQueries
) {
}
