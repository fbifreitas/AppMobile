package com.appbackoffice.api.platform;

import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "platform.bootstrap.enabled=true",
        "platform.bootstrap.tenant-id=tenant-platform",
        "platform.bootstrap.tenant-slug=platform",
        "platform.bootstrap.tenant-name=Platform",
        "platform.bootstrap.admin-email=platform.admin@local.test",
        "platform.bootstrap.admin-name=Platform Admin",
        "platform.bootstrap.admin-password=Platform@123"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PlatformAdminBootstrapIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TenantRepository tenantRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private MembershipRepository membershipRepository;

    @Autowired
    private UserCredentialRepository userCredentialRepository;

    @Test
    void shouldBootstrapPlatformAdminAndAllowLogin() throws Exception {
        assertThat(tenantRepository.findById("tenant-platform")).isPresent();
        var user = userRepository.findByTenantIdAndEmail("tenant-platform", "platform.admin@local.test");
        assertThat(user).isPresent();
        assertThat(membershipRepository.findByUser_IdAndTenant_Id(user.get().getId(), "tenant-platform"))
                .isPresent()
                .get()
                .extracting(membership -> membership.getRole())
                .isEqualTo(MembershipRole.PLATFORM_ADMIN);
        assertThat(userCredentialRepository.findByTenantIdAndUserId("tenant-platform", user.get().getId())).isPresent();

        String loginPayload = """
                {
                  "tenantId": "tenant-platform",
                  "email": "platform.admin@local.test",
                  "password": "Platform@123",
                  "deviceInfo": "web-backoffice"
                }
                """;

        mockMvc.perform(post("/auth/login")
                        .header("X-Correlation-Id", "corr-platform-bootstrap-login")
                        .contentType("application/json")
                        .content(loginPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isString());
    }
}
