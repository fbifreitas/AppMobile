package com.appaigateway.service;

import com.appaigateway.dto.CaseResearchRequest;
import com.appaigateway.dto.CaseResearchResponse;
import com.appaigateway.dto.ResearchFactResponse;
import com.fasterxml.jackson.databind.JsonNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientResponseException;

import java.util.ArrayList;
import java.util.List;

@Service
public class ResearchGatewayService {

    private static final String PROVIDER_NAME = "AI_GATEWAY";
    private static final String PROMPT_VERSION = "v1";
    private static final Logger log = LoggerFactory.getLogger(ResearchGatewayService.class);

    private final GeminiApiClient geminiApiClient;
    private final GeminiPromptBuilder geminiPromptBuilder;
    private final boolean geminiEnabled;
    private final String defaultModel;

    public ResearchGatewayService(GeminiApiClient geminiApiClient,
                                  GeminiPromptBuilder geminiPromptBuilder,
                                  @Value("${app.ai.gemini.enabled:true}") boolean geminiEnabled,
                                  @Value("${app.ai.gemini.model:gemini-3-flash-preview}") String defaultModel) {
        this.geminiApiClient = geminiApiClient;
        this.geminiPromptBuilder = geminiPromptBuilder;
        this.geminiEnabled = geminiEnabled;
        this.defaultModel = defaultModel;
    }

    public CaseResearchResponse execute(CaseResearchRequest request) {
        String model = resolveModel(request);
        if (!geminiEnabled) {
            return buildFallback(model, "GEMINI_DISABLED");
        }

        try {
            GeminiStructuredResearchResult geminiResult = geminiApiClient.generateStructuredResearch(model, geminiPromptBuilder.build(request));
            JsonNode structuredResponse = geminiResult.structuredPayload();
            List<String> qualityFlags = mergeQualityFlags(
                    parseStringArray(structuredResponse.path("qualityFlags")),
                    geminiResult.researchLinks(),
                    geminiResult.webSearchQueries()
            );
            return new CaseResearchResponse(
                    PROVIDER_NAME,
                    model,
                    PROMPT_VERSION,
                    parseFacts(structuredResponse.path("facts")),
                    mergeResearchLinks(
                            parseStringArray(structuredResponse.path("researchLinks")),
                            geminiResult.researchLinks()
                    ),
                    structuredResponse.path("confidenceScore").asDouble(0.0),
                    structuredResponse.path("requiresManualReview").asBoolean(true),
                    qualityFlags
            );
        } catch (Exception exception) {
            log.error("Gemini research request failed for caseId={} model={}", request.caseId(), model, exception);
            return buildFallback(model, classifyQualityFlag(exception));
        }
    }

    private CaseResearchResponse buildFallback(String model, String qualityFlag) {
        return new CaseResearchResponse(
                PROVIDER_NAME,
                model,
                PROMPT_VERSION,
                List.of(),
                List.of(),
                0.0,
                true,
                List.of(qualityFlag)
        );
    }

    private String classifyQualityFlag(Exception exception) {
        if (exception instanceof RestClientResponseException restClientException) {
            int statusCode = restClientException.getStatusCode().value();
            if (statusCode == 429) {
                return "GEMINI_QUOTA_EXCEEDED";
            }
            if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
                return "GEMINI_TEMPORARILY_UNAVAILABLE";
            }
        }
        if (exception instanceof ResourceAccessException) {
            return "GEMINI_TEMPORARILY_UNAVAILABLE";
        }
        return "GEMINI_GATEWAY_ERROR";
    }

    private List<ResearchFactResponse> parseFacts(JsonNode factsNode) {
        if (!factsNode.isArray()) {
            return List.of();
        }

        List<ResearchFactResponse> facts = new ArrayList<>();
        for (JsonNode node : factsNode) {
            facts.add(new ResearchFactResponse(
                    node.path("key").asText(),
                    node.path("value").asText(),
                    node.path("confidence").asDouble(0.0),
                    PROVIDER_NAME,
                    node.path("rationale").asText("")
            ));
        }
        return facts;
    }

    private List<String> parseStringArray(JsonNode node) {
        if (!node.isArray()) {
            return List.of();
        }

        List<String> values = new ArrayList<>();
        for (JsonNode item : node) {
            values.add(item.asText());
        }
        return values;
    }

    private List<String> mergeResearchLinks(List<String> structuredLinks, List<String> groundedLinks) {
        List<String> merged = new ArrayList<>();
        for (String link : structuredLinks) {
            if (!merged.contains(link)) {
                merged.add(link);
            }
        }
        for (String link : groundedLinks) {
            if (!merged.contains(link)) {
                merged.add(link);
            }
        }
        return merged;
    }

    private List<String> mergeQualityFlags(List<String> structuredFlags,
                                           List<String> groundedLinks,
                                           List<String> webSearchQueries) {
        List<String> merged = new ArrayList<>(structuredFlags);
        if (groundedLinks.isEmpty()) {
            merged.add("NO_GROUNDING_LINKS");
        }
        if (webSearchQueries.isEmpty()) {
            merged.add("NO_SEARCH_QUERIES");
        }
        return merged;
    }

    private String resolveModel(CaseResearchRequest request) {
        return request.model() != null && !request.model().isBlank() ? request.model() : defaultModel;
    }
}
