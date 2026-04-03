package com.appbackoffice.api.user;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.appbackoffice.api.user.service.UserService;
import com.appbackoffice.api.user.audit.UserAuditService;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(controllers = UserManagementController.class)
class UserManagementControllerContractErrorTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

        @MockBean
        private UserAuditService userAuditService;

    private static final String CORRELATION_ID = "user-test-corr-001";
    private static final String TENANT_ID = "tenant-a";

    @Test
    void findPendingUsers_withoutCorrelationHeader_returnsBadRequest() throws Exception {
        mockMvc.perform(get("/api/users/pending")
                .header("X-Tenant-Id", TENANT_ID))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                .andExpect(jsonPath("$.severity").value("ERROR"))
                .andExpect(jsonPath("$.message").value(containsString("X-Correlation-Id")))
                .andExpect(jsonPath("$.path").value("/api/users/pending"));
    }

    @Test
    void findPendingUsers_withBlankCorrelationHeader_returnsBadRequest() throws Exception {
        mockMvc.perform(get("/api/users/pending")
                .header("X-Tenant-Id", TENANT_ID)
                .header("X-Correlation-Id", "  "))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                .andExpect(jsonPath("$.severity").value("ERROR"));
    }

    @Test
    void getUserById_withoutCorrelationHeader_returnsBadRequest() throws Exception {
        mockMvc.perform(get("/api/users/1")
                .header("X-Tenant-Id", TENANT_ID))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                .andExpect(jsonPath("$.severity").value("ERROR"));
    }

    @Test
    void approveUser_withoutCorrelationHeader_returnsBadRequest() throws Exception {
        String payload = """
                {
                  "action": "approve"
                }
                """;

        mockMvc.perform(post("/api/users/1/approve")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-Tenant-Id", TENANT_ID)
                .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"));
    }

    @Test
    void rejectUser_withoutCorrelationHeader_returnsBadRequest() throws Exception {
        String payload = """
                {
                  "action": "reject",
                  "reason": "Documentação incompleta"
                }
                """;

        mockMvc.perform(post("/api/users/1/reject")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-Tenant-Id", TENANT_ID)
                .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"));
    }

                @Test
                void createUser_withoutActorHeader_returnsBadRequest() throws Exception {
                                String payload = """
                                                                {
                                                                        "email": "admin@tenant.com",
                                                                        "nome": "Administrador",
                                                                        "tipo": "PJ",
                                                                        "role": "ADMIN"
                                                                }
                                                                """;

                                mockMvc.perform(post("/api/users")
                                                                .contentType(MediaType.APPLICATION_JSON)
                                                                .header("X-Tenant-Id", TENANT_ID)
                                                                .header("X-Correlation-Id", CORRELATION_ID)
                                                                .content(payload))
                                                                .andExpect(status().isBadRequest())
                                                                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                                                                .andExpect(jsonPath("$.message").value(containsString("X-Actor-Id")));
                }

                @Test
                void approveUser_withoutActorHeader_returnsBadRequest() throws Exception {
                                mockMvc.perform(post("/api/users/1/approve")
                                                                .contentType(MediaType.APPLICATION_JSON)
                                                                .header("X-Tenant-Id", TENANT_ID)
                                                                .header("X-Correlation-Id", CORRELATION_ID)
                                                                .content("{}"))
                                                                .andExpect(status().isBadRequest())
                                                                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                                                                .andExpect(jsonPath("$.message").value(containsString("X-Actor-Id")));
                }

                @Test
                void importUsers_withoutActorHeader_returnsBadRequest() throws Exception {
                                String payload = """
                                                                {
                                                                        "users": [
                                                                                {
                                                                                        "email": "import@tenant.com",
                                                                                        "nome": "Importado",
                                                                                        "tipo": "PJ",
                                                                                        "role": "FIELD_AGENT"
                                                                                }
                                                                        ]
                                                                }
                                                                """;

                                mockMvc.perform(post("/api/users/import")
                                                                .contentType(MediaType.APPLICATION_JSON)
                                                                .header("X-Tenant-Id", TENANT_ID)
                                                                .header("X-Correlation-Id", CORRELATION_ID)
                                                                .content(payload))
                                                                .andExpect(status().isBadRequest())
                                                                .andExpect(jsonPath("$.code").value("CTX_MISSING_HEADER"))
                                                                .andExpect(jsonPath("$.message").value(containsString("X-Actor-Id")));
                }
}
