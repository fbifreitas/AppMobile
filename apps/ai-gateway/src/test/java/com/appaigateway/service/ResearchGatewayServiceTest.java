package com.appaigateway.service;

import com.appaigateway.dto.CaseResearchRequest;
import com.appaigateway.dto.CaseResearchResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ResearchGatewayServiceTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void returnsFallbackWhenGeminiIsDisabled() {
        ResearchGatewayService service = new ResearchGatewayService(
                new GeminiApiClient(objectMapper, "https://generativelanguage.googleapis.com", "key", false, 30000),
                new GeminiPromptBuilder(),
                false,
                "gemini-3-flash-preview"
        );

        CaseResearchResponse response = service.execute(sampleRequest());

        assertThat(response.requiresManualReview()).isTrue();
        assertThat(response.qualityFlags()).containsExactly("GEMINI_DISABLED");
    }

    @Test
    void normalizesGeminiFactsUsingGatewaySource() {
        GeminiApiClient geminiApiClient = new StubGeminiApiClient(successfulResponse());
        ResearchGatewayService service = new ResearchGatewayService(
                geminiApiClient,
                new GeminiPromptBuilder(),
                true,
                "gemini-3-flash-preview"
        );

        CaseResearchResponse response = service.execute(sampleRequest());

        assertThat(response.providerName()).isEqualTo("AI_GATEWAY");
        assertThat(response.model()).isEqualTo("gemini-3-flash-preview");
        assertThat(response.facts()).hasSize(1);
        assertThat(response.facts().get(0).source()).isEqualTo("AI_GATEWAY");
        assertThat(response.facts().get(0).key()).isEqualTo("initial_context");
        assertThat(response.confidenceScore()).isEqualTo(0.88);
        assertThat(response.requiresManualReview()).isFalse();
        assertThat(response.researchLinks()).containsExactly("https://grounded.example/source");
        assertThat(response.qualityFlags()).containsExactly("GROUNDING_OK");
    }

    private CaseResearchRequest sampleRequest() {
        return new CaseResearchRequest(
                "tenant-platform",
                "case-1",
                "CASE-1",
                "Rua Exemplo, 123",
                "APARTMENT",
                "gemini-3-flash-preview"
        );
    }

    private ObjectNode successfulResponse() {
        ObjectNode root = objectMapper.createObjectNode();
        ArrayNode facts = root.putArray("facts");
        facts.addObject()
                .put("key", "initial_context")
                .put("value", "Facade")
                .put("confidence", 0.88)
                .put("rationale", "Facade-first recommendation");
        root.putArray("researchLinks").add("https://example.com/ad");
        root.putArray("qualityFlags").add("GROUNDING_OK");
        root.put("confidenceScore", 0.88);
        root.put("requiresManualReview", false);
        return root;
    }

    private static class StubGeminiApiClient extends GeminiApiClient {

        private final ObjectNode structuredResponse;

        StubGeminiApiClient(ObjectNode structuredResponse) {
            super(new ObjectMapper(), "https://generativelanguage.googleapis.com", "key", false, 30000);
            this.structuredResponse = structuredResponse;
        }

        @Override
        public GeminiStructuredResearchResult generateStructuredResearch(String model, String prompt) {
            return new GeminiStructuredResearchResult(
                    structuredResponse,
                    java.util.List.of("https://grounded.example/source"),
                    java.util.List.of("alvaro ramos 760 apto 102 sao paulo")
            );
        }
    }
}
