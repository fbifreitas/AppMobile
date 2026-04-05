package com.appbackoffice.api.mobile;

import com.appbackoffice.api.job.service.JobService;
import com.appbackoffice.api.mobile.service.InspectionSubmissionService;
import com.appbackoffice.api.mobile.service.MobileCheckinConfigService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
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

    @MockBean
    private JobService jobService;

    @MockBean
    private InspectionSubmissionService inspectionSubmissionService;

    @MockBean
    private MobileCheckinConfigService mobileCheckinConfigService;

    @Test
    void getCheckinConfig_withoutTenantHeader_returnsCanonicalContextError() throws Exception {
        mockMvc.perform(get("/api/mobile/checkin-config")
                        .header("X-Correlation-Id", "corr-123")
                        .header("X-Actor-Id", "actor-1")
                        .header("X-Api-Version", "v1"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                .andExpect(jsonPath("$.severity").value("ERROR"))
                .andExpect(jsonPath("$.guidance").value("Informe os cabecalhos de contexto e tente novamente."))
                .andExpect(jsonPath("$.path").value("/api/mobile/checkin-config"));
    }

    @Test
    void getCheckinConfig_withoutApiVersion_returnsContractVersionRequired() throws Exception {
        mockMvc.perform(get("/api/mobile/checkin-config")
                        .header("X-Tenant-Id", "tenant-a")
                        .header("X-Correlation-Id", "corr-123")
                        .header("X-Actor-Id", "actor-1"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CONTRACT_VERSION_REQUIRED"));
    }

    @Test
    void getCheckinConfig_withUnsupportedApiVersion_returnsPreconditionFailed() throws Exception {
        mockMvc.perform(get("/api/mobile/checkin-config")
                        .header("X-Tenant-Id", "tenant-a")
                        .header("X-Correlation-Id", "corr-123")
                        .header("X-Actor-Id", "actor-1")
                        .header("X-Api-Version", "v0"))
                .andExpect(status().isPreconditionFailed())
                .andExpect(jsonPath("$.code").value("CONTRACT_VERSION_UNSUPPORTED"));
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
                        .header("X-Api-Version", "v1")
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("IDEMPOTENCY_KEY_REQUIRED"))
                .andExpect(jsonPath("$.severity").value("ERROR"))
                .andExpect(jsonPath("$.message", containsString("X-Idempotency-Key")))
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
                        .header("X-Api-Version", "v1")
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
                        .header("X-Actor-Id", "actor-1")
                        .header("X-Api-Version", "v1"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                .andExpect(jsonPath("$.message", containsString("X-Tenant-Id")))
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
                        .header("X-Api-Version", "v1")
                        .header("X-Idempotency-Key", "idem-123")
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                .andExpect(jsonPath("$.message", containsString("X-Correlation-Id")))
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
                        .header("X-Api-Version", "v1")
                        .header("X-Idempotency-Key", " ")
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("IDEMPOTENCY_KEY_REQUIRED"))
                .andExpect(jsonPath("$.message", containsString("X-Idempotency-Key")))
                .andExpect(jsonPath("$.details").value("header: X-Idempotency-Key"));
    }
}
