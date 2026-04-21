package com.appaigateway.controller;

import com.appaigateway.dto.CaseResearchRequest;
import com.appaigateway.dto.CaseResearchResponse;
import com.appaigateway.dto.ResearchFactResponse;
import com.appaigateway.service.GatewayApiKeyAuthorizer;
import com.appaigateway.service.ResearchGatewayService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.context.TestPropertySource;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ResearchGatewayController.class)
@Import(GatewayApiKeyAuthorizer.class)
@TestPropertySource(properties = "app.gateway.api-key=test-gateway-key")
class ResearchGatewayControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ResearchGatewayService researchGatewayService;

    @Test
    void rejectsRequestWhenGatewayApiKeyIsInvalid() throws Exception {
        mockMvc.perform(post("/v1/research/cases")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Api-Key", "wrong-key")
                        .content(objectMapper.writeValueAsString(sampleRequest())))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void returnsStructuredResearchResponseWhenGatewayApiKeyIsValid() throws Exception {
        given(researchGatewayService.execute(any(CaseResearchRequest.class)))
                .willReturn(new CaseResearchResponse(
                        "AI_GATEWAY",
                        "gemini-3-flash-preview",
                        "v1",
                        List.of(new ResearchFactResponse("initial_context", "Facade", 0.91, "AI_GATEWAY", "Facade-first")),
                        List.of("https://example.com/ad"),
                        0.91,
                        false,
                        List.of()
                ));

        mockMvc.perform(post("/v1/research/cases")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Api-Key", "test-gateway-key")
                        .content(objectMapper.writeValueAsString(sampleRequest())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.providerName").value("AI_GATEWAY"))
                .andExpect(jsonPath("$.facts[0].key").value("initial_context"))
                .andExpect(jsonPath("$.confidenceScore").value(0.91));
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
}
