package com.appaigateway.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Component
public class GeminiApiClient {

    private final ObjectMapper objectMapper;
    private final RestClient restClient;
    private final String baseUrl;
    private final String apiKey;
    private final boolean groundingEnabled;

    public GeminiApiClient(ObjectMapper objectMapper,
                           @Value("${app.ai.gemini.base-url}") String baseUrl,
                           @Value("${app.ai.gemini.api-key}") String apiKey,
                           @Value("${app.ai.gemini.grounding-enabled:false}") boolean groundingEnabled,
                           @Value("${app.ai.gemini.timeout-ms:30000}") int timeoutMs) {
        this.objectMapper = objectMapper;
        this.baseUrl = trimTrailingSlash(baseUrl);
        this.apiKey = apiKey;
        this.groundingEnabled = groundingEnabled;
        this.restClient = RestClient.builder()
                .requestFactory(buildRequestFactory(timeoutMs))
                .build();
    }

    public GeminiStructuredResearchResult generateStructuredResearch(String model, String prompt) {
        JsonNode response = restClient.post()
                .uri(baseUrl + "/v1beta/models/" + model + ":generateContent")
                .contentType(MediaType.APPLICATION_JSON)
                .header(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
                .header("x-goog-api-key", apiKey)
                .body(buildRequest(prompt))
                .retrieve()
                .body(JsonNode.class);

        JsonNode textNode = response == null
                ? null
                : response.path("candidates").path(0).path("content").path("parts").path(0).path("text");
        JsonNode groundingMetadata = response == null
                ? objectMapper.createObjectNode()
                : response.path("candidates").path(0).path("groundingMetadata");

        if (textNode == null || textNode.isMissingNode() || textNode.asText().isBlank()) {
            return new GeminiStructuredResearchResult(
                    objectMapper.createObjectNode(),
                    parseResearchLinks(groundingMetadata),
                    parseWebSearchQueries(groundingMetadata)
            );
        }

        try {
            return new GeminiStructuredResearchResult(
                    objectMapper.readTree(textNode.asText()),
                    parseResearchLinks(groundingMetadata),
                    parseWebSearchQueries(groundingMetadata)
            );
        } catch (Exception exception) {
            throw new IllegalStateException("Gemini gateway returned non-JSON structured content", exception);
        }
    }

    private JsonNode buildRequest(String prompt) {
        ObjectNode root = objectMapper.createObjectNode();
        ArrayNode contents = root.putArray("contents");
        ObjectNode content = contents.addObject();
        ArrayNode parts = content.putArray("parts");
        parts.addObject().put("text", prompt);

        ObjectNode generationConfig = root.putObject("generationConfig");
        generationConfig.put("responseMimeType", "application/json");
        generationConfig.set("responseSchema", buildResponseSchema());

        if (groundingEnabled) {
            ArrayNode tools = root.putArray("tools");
            tools.addObject().putObject("google_search");
        }
        return root;
    }

    private JsonNode buildResponseSchema() {
        ObjectNode schema = objectMapper.createObjectNode();
        schema.put("type", "object");

        ObjectNode properties = schema.putObject("properties");
        properties.set("facts", buildFactsSchema());
        properties.set("researchLinks", buildStringArraySchema());
        properties.set("qualityFlags", buildStringArraySchema());
        properties.putObject("confidenceScore").put("type", "number");
        properties.putObject("requiresManualReview").put("type", "boolean");

        ArrayNode required = schema.putArray("required");
        required.add("facts");
        required.add("researchLinks");
        required.add("qualityFlags");
        required.add("confidenceScore");
        required.add("requiresManualReview");
        return schema;
    }

    private JsonNode buildFactsSchema() {
        ObjectNode schema = objectMapper.createObjectNode();
        schema.put("type", "array");
        ObjectNode items = schema.putObject("items");
        items.put("type", "object");
        ObjectNode properties = items.putObject("properties");
        properties.putObject("key").put("type", "string");
        properties.putObject("value").put("type", "string");
        properties.putObject("confidence").put("type", "number");
        properties.putObject("rationale").put("type", "string");
        ArrayNode required = items.putArray("required");
        required.add("key");
        required.add("value");
        required.add("confidence");
        required.add("rationale");
        return schema;
    }

    private JsonNode buildStringArraySchema() {
        ObjectNode schema = objectMapper.createObjectNode();
        schema.put("type", "array");
        schema.putObject("items").put("type", "string");
        return schema;
    }

    private SimpleClientHttpRequestFactory buildRequestFactory(int timeoutMs) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(timeoutMs);
        factory.setReadTimeout(timeoutMs);
        return factory;
    }

    private List<String> parseResearchLinks(JsonNode groundingMetadata) {
        Set<String> links = new LinkedHashSet<>();
        JsonNode groundingChunks = groundingMetadata.path("groundingChunks");
        if (!groundingChunks.isArray()) {
            return List.of();
        }

        for (JsonNode chunk : groundingChunks) {
            String uri = chunk.path("web").path("uri").asText("");
            if (!uri.isBlank()) {
                links.add(uri);
            }
        }
        return new ArrayList<>(links);
    }

    private List<String> parseWebSearchQueries(JsonNode groundingMetadata) {
        JsonNode webSearchQueries = groundingMetadata.path("webSearchQueries");
        if (!webSearchQueries.isArray()) {
            return List.of();
        }

        List<String> queries = new ArrayList<>();
        for (JsonNode query : webSearchQueries) {
            String value = query.asText("");
            if (!value.isBlank()) {
                queries.add(value);
            }
        }
        return queries;
    }

    private String trimTrailingSlash(String value) {
        if (value == null || value.isBlank()) {
            return "https://generativelanguage.googleapis.com";
        }
        return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
    }
}
