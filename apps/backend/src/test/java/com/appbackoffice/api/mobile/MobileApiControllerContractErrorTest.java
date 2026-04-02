package com.appbackoffice.api.mobile;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = MobileApiController.class)
class MobileApiControllerContractErrorTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void getCheckinConfig_withoutTenantHeader_returnsCanonicalContextError() throws Exception {
        mockMvc.perform(get("/api/mobile/checkin-config")
                        .header("X-Correlation-Id", "corr-123")
                        .header("X-Actor-Id", "actor-1"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                .andExpect(jsonPath("$.severity").value("ERROR"))
                .andExpect(jsonPath("$.guidance").value("Informe os cabeçalhos de contexto e tente novamente."))
                .andExpect(jsonPath("$.path").value("/api/mobile/checkin-config"));
    }

    @Test
    void postInspectionFinalized_withoutIdempotencyHeader_returnsCanonicalError() throws Exception {
        String payload = """
                {
                  "exportedAt": "2026-04-01T10:15:30Z",
                  "job": {"id": "job-123", "titulo": "Inspecao"},
                  "step1": {},
                  "step2": {},
                  "step2Config": {},
                  "review": {}
                }
                """;

        mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Tenant-Id", "tenant-a")
                        .header("X-Correlation-Id", "corr-123")
                        .header("X-Actor-Id", "actor-1")
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("IDEMPOTENCY_KEY_REQUIRED"))
                .andExpect(jsonPath("$.severity").value("ERROR"))
                .andExpect(jsonPath("$.message").value("X-Idempotency-Key é obrigatório"))
                .andExpect(jsonPath("$.details").value("header: X-Idempotency-Key"));
    }

    @Test
    void postInspectionFinalized_withInvalidPayload_returnsValidationCanonicalError() throws Exception {
        String invalidPayload = """
                {
                  "job": {"id": "job-123", "titulo": "Inspecao"},
                  "step1": {},
                  "step2": {},
                  "step2Config": {},
                  "review": {}
                }
                """;

        mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Tenant-Id", "tenant-a")
                        .header("X-Correlation-Id", "corr-123")
                        .header("X-Actor-Id", "actor-1")
                        .header("X-Idempotency-Key", "idem-123")
                        .content(invalidPayload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("REQ_VALIDATION_FAILED"))
                .andExpect(jsonPath("$.severity").value("ERROR"))
                .andExpect(jsonPath("$.details", containsString("exportedAt")));
    }

    @Test
    void getCheckinConfig_withBlankTenantHeader_returnsCanonicalContextError() throws Exception {
        mockMvc.perform(get("/api/mobile/checkin-config")
                        .header("X-Tenant-Id", " ")
                        .header("X-Correlation-Id", "corr-123")
                        .header("X-Actor-Id", "actor-1"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                .andExpect(jsonPath("$.message").value("X-Tenant-Id é obrigatório"))
                .andExpect(jsonPath("$.details").value("header: X-Tenant-Id"));
    }

    @Test
    void postInspectionFinalized_withoutCorrelationHeader_returnsCanonicalContextError() throws Exception {
        String payload = """
                {
                  "exportedAt": "2026-04-01T10:15:30Z",
                  "job": {"id": "job-123", "titulo": "Inspecao"},
                  "step1": {},
                  "step2": {},
                  "step2Config": {},
                  "review": {}
                }
                """;

        mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Tenant-Id", "tenant-a")
                        .header("X-Actor-Id", "actor-1")
                        .header("X-Idempotency-Key", "idem-123")
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                .andExpect(jsonPath("$.message").value("X-Correlation-Id é obrigatório"))
                .andExpect(jsonPath("$.details").value("header: X-Correlation-Id"));
    }

    @Test
    void postInspectionFinalized_withBlankIdempotencyHeader_returnsCanonicalError() throws Exception {
        String payload = """
                {
                  "exportedAt": "2026-04-01T10:15:30Z",
                  "job": {"id": "job-123", "titulo": "Inspecao"},
                  "step1": {},
                  "step2": {},
                  "step2Config": {},
                  "review": {}
                }
                """;

        mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Tenant-Id", "tenant-a")
                        .header("X-Correlation-Id", "corr-123")
                        .header("X-Actor-Id", "actor-1")
                        .header("X-Idempotency-Key", " ")
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("IDEMPOTENCY_KEY_REQUIRED"))
                .andExpect(jsonPath("$.message").value("X-Idempotency-Key é obrigatório"))
                .andExpect(jsonPath("$.details").value("header: X-Idempotency-Key"));
    }
}