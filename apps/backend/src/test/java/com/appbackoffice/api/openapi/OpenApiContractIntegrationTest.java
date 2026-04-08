package com.appbackoffice.api.openapi;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.MockMvc;

import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OpenApiContractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void openApiDocument_exposesCanonicalErrorSchemaAndRequiredContextHeaders() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/openapi/v1"))
            .andReturn();

        assertThat(result.getResponse().getStatus())
            .withFailMessage(openApiFailureMessage(result))
            .isEqualTo(200);

        String content = result.getResponse().getContentAsString();

        JsonNode document = objectMapper.readTree(content);

        JsonNode canonicalError = document.at("/components/schemas/CanonicalErrorResponse");
        assertThat(canonicalError.isMissingNode()).isFalse();
        assertThat(jsonTextValues(canonicalError.path("required")))
                .contains(
                        "timestamp",
                        "code",
                        "severity",
                        "message",
                        "guidance",
                        "correlationId",
                        "path"
                );

        JsonNode severity = document.at("/components/schemas/ErrorSeverity");
        assertThat(severity.isMissingNode()).isFalse();
        assertThat(jsonTextValues(severity.path("enum"))).contains("ERROR", "WARNING");

        JsonNode getResponses = document.at("/paths/~1api~1mobile~1checkin-config/get/responses");
        assertThat(getResponses.at("/400/content/application~1json/schema/$ref").asText())
                .isEqualTo("#/components/schemas/CanonicalErrorResponse");
        assertThat(requiredHeaderNames(document, "/api/mobile/checkin-config", "get"))
                .containsExactlyInAnyOrder("X-Tenant-Id", "X-Correlation-Id", "X-Actor-Id", "X-Api-Version");

        JsonNode postResponses = document.at("/paths/~1api~1mobile~1inspections~1finalized/post/responses");
        assertThat(postResponses.at("/400/content/application~1json/schema/$ref").asText())
                .isEqualTo("#/components/schemas/CanonicalErrorResponse");
        assertThat(postResponses.at("/409/content/application~1json/schema/$ref").asText())
                .isEqualTo("#/components/schemas/CanonicalErrorResponse");
        assertThat(requiredHeaderNames(document, "/api/mobile/inspections/finalized", "post"))
                .containsExactlyInAnyOrder(
                        "X-Tenant-Id",
                        "X-Correlation-Id",
                        "X-Actor-Id",
                        "X-Idempotency-Key",
                        "X-Request-Timestamp",
                        "X-Request-Nonce",
                        "X-Api-Version"
                );

        assertThat(requiredHeaderNames(document, "/api/backoffice/config/packages", "get"))
            .containsExactlyInAnyOrder("X-Correlation-Id");
        assertThat(requiredHeaderNames(document, "/api/backoffice/config/packages", "post"))
            .containsExactlyInAnyOrder("X-Correlation-Id");
        assertThat(requiredHeaderNames(document, "/api/backoffice/config/packages/approve", "post"))
            .containsExactlyInAnyOrder("X-Correlation-Id");
    }

    private String openApiFailureMessage(MvcResult result) {
        Exception resolvedException = result.getResolvedException();
        if (resolvedException == null) {
            return "OpenAPI endpoint returned " + result.getResponse().getStatus()
                    + " with body: " + responseBody(result);
        }

        Throwable rootCause = resolvedException;
        while (rootCause.getCause() != null) {
            rootCause = rootCause.getCause();
        }

        return "OpenAPI endpoint returned " + result.getResponse().getStatus()
                + " with exception " + rootCause.getClass().getName()
                + ": " + rootCause.getMessage()
                + " and body: " + responseBody(result);
    }

    private String responseBody(MvcResult result) {
        return new String(result.getResponse().getContentAsByteArray(), StandardCharsets.UTF_8);
    }

    private Set<String> requiredHeaderNames(JsonNode document, String path, String method) {
        JsonNode parameters = document.path("paths").path(path).path(method).path("parameters");
        Set<String> names = new HashSet<>();

        if (!parameters.isArray()) {
            return names;
        }

        Iterator<JsonNode> iterator = parameters.elements();
        while (iterator.hasNext()) {
            JsonNode parameter = iterator.next();
            if ("header".equals(parameter.path("in").asText()) && parameter.path("required").asBoolean(false)) {
                names.add(parameter.path("name").asText());
            }
        }

        return names;
    }

    private Set<String> jsonTextValues(JsonNode node) {
        Set<String> values = new HashSet<>();
        if (!node.isArray()) {
            return values;
        }

        Iterator<JsonNode> iterator = node.elements();
        while (iterator.hasNext()) {
            values.add(iterator.next().asText());
        }

        return values;
    }
}
