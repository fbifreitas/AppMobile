package com.appbackoffice.api.config;

import com.appbackoffice.api.contract.ApiExceptionHandler;
import com.appbackoffice.api.security.SecurityWebMvcConfig;
import com.appbackoffice.api.security.TenantRoleAuthorizationInterceptor;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ConfigPackageController.class)
@Import({ApiExceptionHandler.class, SecurityWebMvcConfig.class, TenantRoleAuthorizationInterceptor.class})
class ConfigPackageAuthorizationContractTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ConfigPackageService configPackageService;

    @Test
    void listPackages_withOperatorRole_returnsForbidden() throws Exception {
        mockMvc.perform(get("/api/backoffice/config/packages")
                        .queryParam("tenantId", "tenant-alpha")
                        .queryParam("actorRole", "operator")
                        .header("X-Correlation-Id", "corr-authz-001"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("AUTH_FORBIDDEN"));
    }
}
