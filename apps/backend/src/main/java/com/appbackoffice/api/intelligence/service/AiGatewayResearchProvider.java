package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.port.ResearchFact;
import com.appbackoffice.api.intelligence.port.ResearchProvider;
import com.appbackoffice.api.intelligence.port.ResearchProviderRequest;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;

@Component
@ConditionalOnProperty(name = "integration.ai-gateway.enabled", havingValue = "true")
public class AiGatewayResearchProvider implements ResearchProvider {

    private final RestClient restClient;
    private final ObjectMapper objectMapper;
    private final String baseUrl;
    private final String apiKey;
    private final String model;
    private final String researchPath;

    public AiGatewayResearchProvider(ObjectMapper objectMapper,
                                     @Value("${integration.ai-gateway.base-url}") String baseUrl,
                                     @Value("${integration.ai-gateway.api-key}") String apiKey,
                                     @Value("${integration.ai-gateway.model}") String model,
                                     @Value("${integration.ai-gateway.research-path:/v1/research/cases}") String researchPath) {
        this.objectMapper = objectMapper;
        this.baseUrl = trimTrailingSlash(baseUrl);
        this.apiKey = apiKey;
        this.model = model;
        this.researchPath = researchPath;
        this.restClient = RestClient.builder().build();
    }

    @Override
    public ResearchProviderResponse execute(ResearchProviderRequest request) {
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("tenantId", request.tenantId());
        payload.put("caseId", request.caseId());
        payload.put("caseNumber", request.caseNumber());
        payload.put("propertyAddress", request.propertyAddress());
        payload.put("assetType", request.assetType());
        payload.put("model", model);

        JsonNode responseNode = restClient.post()
                .uri(baseUrl + normalizePath(researchPath))
                .contentType(MediaType.APPLICATION_JSON)
                .header(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
                .header("X-Api-Key", apiKey)
                .body(payload)
                .retrieve()
                .body(JsonNode.class);

        JsonNode safeResponse = responseNode == null ? objectMapper.createObjectNode() : responseNode;
        List<ResearchFact> facts = parseFacts(safeResponse.path("facts"));
        List<String> links = parseLinks(safeResponse.path("researchLinks"));
        double confidence = safeResponse.path("confidenceScore").asDouble(0.0);
        boolean requiresManualReview = safeResponse.path("requiresManualReview").asBoolean(facts.isEmpty());
        List<String> qualityFlags = parseLinks(safeResponse.path("qualityFlags"));

        return new ResearchProviderResponse(
                safeResponse.path("providerName").asText("AI_GATEWAY"),
                safeResponse.path("model").asText(model),
                safeResponse.path("promptVersion").asText("v1"),
                facts,
                links,
                safeResponse,
                buildNormalizedPayload(request, facts, links, confidence, requiresManualReview, qualityFlags),
                confidence,
                requiresManualReview,
                qualityFlags
        );
    }

    private JsonNode buildNormalizedPayload(ResearchProviderRequest request,
                                            List<ResearchFact> facts,
                                            List<String> links,
                                            double confidence,
                                            boolean requiresManualReview,
                                            List<String> qualityFlags) {
        ObjectNode normalized = objectMapper.createObjectNode();
        normalized.put("tenantId", request.tenantId());
        normalized.put("caseId", request.caseId());
        normalized.put("assetType", request.assetType());
        normalized.put("confidenceScore", confidence);
        normalized.put("requiresManualReview", requiresManualReview);
        ArrayNode factsNode = normalized.putArray("facts");
        for (ResearchFact fact : facts) {
            ObjectNode factNode = factsNode.addObject();
            factNode.put("key", fact.key());
            factNode.put("value", fact.value());
            factNode.put("confidence", fact.confidence());
            factNode.put("source", fact.source());
            factNode.put("rationale", fact.rationale());
        }
        ArrayNode linksNode = normalized.putArray("researchLinks");
        links.forEach(linksNode::add);
        ArrayNode flagsNode = normalized.putArray("qualityFlags");
        qualityFlags.forEach(flagsNode::add);
        return normalized;
    }

    private List<ResearchFact> parseFacts(JsonNode factsNode) {
        List<ResearchFact> facts = new ArrayList<>();
        if (!factsNode.isArray()) {
            return facts;
        }
        for (JsonNode node : factsNode) {
            facts.add(new ResearchFact(
                    node.path("key").asText(),
                    node.path("value").asText(),
                    node.path("confidence").asDouble(0.0),
                    node.path("source").asText("AI_GATEWAY"),
                    node.path("rationale").asText("")
            ));
        }
        return facts;
    }

    private List<String> parseLinks(JsonNode linksNode) {
        List<String> links = new ArrayList<>();
        if (!linksNode.isArray()) {
            return links;
        }
        for (JsonNode node : linksNode) {
            links.add(node.asText());
        }
        return links;
    }

    private String trimTrailingSlash(String value) {
        if (value == null) {
            return "";
        }
        return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }

    private String normalizePath(String value) {
        if (value == null || value.isBlank()) {
            return "/v1/research/cases";
        }
        return value.startsWith("/") ? value : "/" + value;
    }
}
