package com.appbackoffice.api.user;

import com.appbackoffice.api.auth.repository.IdentityBindingRepository;
import com.appbackoffice.api.auth.repository.SessionRepository;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.identity.entity.MembershipStatus;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserLifecycleStatus;
import com.appbackoffice.api.user.repository.UserLifecycleRepository;
import com.appbackoffice.api.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class UserLifecycleTransitionIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserLifecycleRepository userLifecycleRepository;

    @Autowired
    private MembershipRepository membershipRepository;

    @Autowired
    private TenantRepository tenantRepository;

    @Autowired
    private SessionRepository sessionRepository;

    @Autowired
    private UserCredentialRepository userCredentialRepository;

    @Autowired
    private IdentityBindingRepository identityBindingRepository;

    private static final String TENANT_ID = "tenant-lifecycle-transition";
    private static final String CORRELATION_ID = "corr-lifecycle-transition-001";
    private static final String ACTOR_ID = "backoffice-admin";

    @BeforeEach
    void setUp() {
        sessionRepository.deleteAll();
        identityBindingRepository.deleteAll();
        userCredentialRepository.deleteAll();
        membershipRepository.deleteAll();
        userLifecycleRepository.deleteAll();
        userRepository.deleteAll();
        tenantRepository.deleteAll();
        tenantRepository.save(new Tenant(TENANT_ID, "tenant-lifecycle-transition", "Tenant Lifecycle Transition", TenantStatus.ACTIVE));
    }

    @Test
    void shouldCreatePendingLifecycleAndTransitionToApproved() throws Exception {
        User created = userRepository.save(new User(TENANT_ID, "lifecycle@tenant.com", "Lifecycle User", "PJ"));
        Long userId = created.getId();

        mockMvc.perform(post("/api/users/{userId}/approve", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", ACTOR_ID)
                        .content("{}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("APPROVED"))
                .andExpect(jsonPath("$.lifecycleStatus").value("APPROVED"));

        var lifecycle = userLifecycleRepository.findByUserIdAndTenantId(userId, TENANT_ID).orElseThrow();
        assertThat(lifecycle.getStatus()).isEqualTo(UserLifecycleStatus.APPROVED);

        var membership = membershipRepository.findByUser_IdAndTenant_Id(userId, TENANT_ID).orElseThrow();
        assertThat(membership.getStatus()).isEqualTo(MembershipStatus.ACTIVE);
    }

    @Test
    void shouldTransitionLifecycleToRejectedWithReason() throws Exception {
        User created = userRepository.save(new User(TENANT_ID, "rejected@tenant.com", "Rejected User", "CLT"));
        Long userId = created.getId();

        String rejectPayload = """
                {
                  "action": "reject",
                  "reason": "Documentacao inconsistente"
                }
                """;

        mockMvc.perform(post("/api/users/{userId}/reject", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", ACTOR_ID)
                        .content(rejectPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REJECTED"))
                .andExpect(jsonPath("$.lifecycleStatus").value("REJECTED"));

        var lifecycle = userLifecycleRepository.findByUserIdAndTenantId(userId, TENANT_ID).orElseThrow();
        assertThat(lifecycle.getStatus()).isEqualTo(UserLifecycleStatus.REJECTED);
        assertThat(lifecycle.getReason()).isEqualTo("Documentacao inconsistente");

        var membership = membershipRepository.findByUser_IdAndTenant_Id(userId, TENANT_ID).orElseThrow();
        assertThat(membership.getStatus()).isEqualTo(MembershipStatus.REVOKED);
    }
}
