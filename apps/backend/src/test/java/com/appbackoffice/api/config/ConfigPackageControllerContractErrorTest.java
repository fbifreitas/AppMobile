package com.appbackoffice.api.config;

import com.appbackoffice.api.contract.ApiExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ConfigPackageController.class)
@Import(ApiExceptionHandler.class)
class ConfigPackageControllerContractErrorTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ConfigPackageService configPackageService;

    @Test
    void listPackages_withoutCorrelationHeader_returnsCanonicalContextError() throws Exception {
        mockMvc.perform(get("/api/backoffice/config/packages")
                        .queryParam("tenantId", "tenant-alpha")
                        .queryParam("actorRole", "tenant_admin"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                .andExpect(jsonPath("$.message").value("X-Correlation-Id é obrigatório"))
                .andExpect(jsonPath("$.details").value("header: X-Correlation-Id"));
    }

    @Test
    void approve_withBlankCorrelationHeader_returnsCanonicalContextError() throws Exception {
        mockMvc.perform(post("/api/backoffice/config/packages/approve")
                        .header("X-Correlation-Id", " ")
                        .contentType("application/json")
                        .content("""
                                {
                                  "packageId": "cfg-001",
                                  "tenantId": "tenant-alpha",
                                  "actorId": "approver-web",
                                  "actorRole": "tenant_admin"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                .andExpect(jsonPath("$.message").value("X-Correlation-Id é obrigatório"))
                .andExpect(jsonPath("$.details").value("header: X-Correlation-Id"));
    }
}