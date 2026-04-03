package com.appbackoffice.api.user;

import com.appbackoffice.api.identity.entity.Membership;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.identity.entity.MembershipStatus;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.auth.repository.IdentityBindingRepository;
import com.appbackoffice.api.auth.repository.SessionRepository;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.user.audit.UserAuditEntryRepository;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserRole;
import com.appbackoffice.api.user.entity.UserSource;
import com.appbackoffice.api.user.entity.UserStatus;
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
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class UserManagementLifecycleIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

        @Autowired
        private MembershipRepository membershipRepository;

        @Autowired
        private TenantRepository tenantRepository;

        @Autowired
        private UserAuditEntryRepository userAuditEntryRepository;

        @Autowired
        private SessionRepository sessionRepository;

        @Autowired
        private UserCredentialRepository userCredentialRepository;

        @Autowired
        private IdentityBindingRepository identityBindingRepository;

    private static final String CORRELATION_ID = "user-lifecycle-corr-001";
        private static final String TENANT_ID = "tenant-lifecycle-test";
        private static final String ACTOR_ID = "backoffice-admin";

    @BeforeEach
    void setUp() {
                sessionRepository.deleteAll();
                identityBindingRepository.deleteAll();
                userCredentialRepository.deleteAll();
                membershipRepository.deleteAll();
                userAuditEntryRepository.deleteAll();
        userRepository.deleteAll();
                tenantRepository.deleteAll();
        tenantRepository.save(new Tenant(TENANT_ID, "tenant-lifecycle-test", "Tenant Lifecycle Test", TenantStatus.ACTIVE));
    }

    @Test
    void completeUserApprovalLifecycle() throws Exception {
        // Step 1: Create a pending user
        User user = new User(TENANT_ID, "joao@lifecycle.com", "João Silva", "PJ");
        user.setCnpj("12345678901234");
        User savedUser = userRepository.save(user);
        Long userId = savedUser.getId();

        // Step 2: List pending users
        mockMvc.perform(get("/api/users/pending")
                .header("X-Tenant-Id", TENANT_ID)
                .header("X-Correlation-Id", CORRELATION_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(1))
                .andExpect(jsonPath("$.users", hasSize(1)))
                .andExpect(jsonPath("$.users[0].email").value("joao@lifecycle.com"))
                .andExpect(jsonPath("$.users[0].status").value("AWAITING_APPROVAL"));

        // Step 3: Get user details
        mockMvc.perform(get("/api/users/" + userId)
                .header("X-Tenant-Id", TENANT_ID)
                .header("X-Correlation-Id", CORRELATION_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(userId))
                .andExpect(jsonPath("$.email").value("joao@lifecycle.com"))
                .andExpect(jsonPath("$.status").value("AWAITING_APPROVAL"))
                .andExpect(jsonPath("$.approvedAt").doesNotExist());

        // Step 4: Approve the user
        mockMvc.perform(post("/api/users/" + userId + "/approve")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-Tenant-Id", TENANT_ID)
                .header("X-Correlation-Id", CORRELATION_ID)
                .header("X-Actor-Id", ACTOR_ID)
                .content("{}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("APPROVED"))
                .andExpect(jsonPath("$.approvedAt").exists());

        mockMvc.perform(get("/api/users/audit")
                .header("X-Tenant-Id", TENANT_ID)
                .header("X-Correlation-Id", CORRELATION_ID)
                .header("X-Actor-Id", ACTOR_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.count", is(1)))
                .andExpect(jsonPath("$.items[0].action").value("USER_APPROVED"))
                .andExpect(jsonPath("$.items[0].actorId").value(ACTOR_ID));

        // Step 5: Verify user is no longer in pending list
        mockMvc.perform(get("/api/users/pending")
                .header("X-Tenant-Id", TENANT_ID)
                .header("X-Correlation-Id", CORRELATION_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(0))
                .andExpect(jsonPath("$.users", hasSize(0)));

        // Step 6: Verify final state in database
        User approved = userRepository.findById(userId).orElseThrow();
        assertThat(approved.getStatus()).isEqualTo(UserStatus.APPROVED);
        assertThat(approved.getApprovedAt()).isNotNull();
    }

    @Test
    void completeUserRejectionLifecycle() throws Exception {
        // Step 1: Create a pending user
        User user = new User(TENANT_ID, "maria@lifecycle.com", "Maria Silva", "CLT");
        user.setCpf("12345678901");
        User savedUser = userRepository.save(user);
        Long userId = savedUser.getId();

        // Step 2: Reject the user with reason
        String rejectPayload = """
                {
                  "action": "reject",
                  "reason": "Documentação incompleta para perfil PJ"
                }
                """;

        mockMvc.perform(post("/api/users/" + userId + "/reject")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-Tenant-Id", TENANT_ID)
                .header("X-Correlation-Id", CORRELATION_ID)
                .header("X-Actor-Id", ACTOR_ID)
                .content(rejectPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REJECTED"))
                .andExpect(jsonPath("$.rejectionReason").value("Documentação incompleta para perfil PJ"))
                .andExpect(jsonPath("$.rejectedAt").exists());

        mockMvc.perform(get("/api/users/audit?userId=" + userId)
                .header("X-Tenant-Id", TENANT_ID)
                .header("X-Correlation-Id", CORRELATION_ID)
                .header("X-Actor-Id", ACTOR_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.count", is(1)))
                .andExpect(jsonPath("$.items[0].action").value("USER_REJECTED"))
                .andExpect(jsonPath("$.items[0].details").value("reason=Documentação incompleta para perfil PJ"));

        // Step 3: Verify no longer in pending list
        mockMvc.perform(get("/api/users/pending")
                .header("X-Tenant-Id", TENANT_ID)
                .header("X-Correlation-Id", CORRELATION_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(0));

        // Step 4: Verify final state in database
        User rejected = userRepository.findById(userId).orElseThrow();
        assertThat(rejected.getStatus()).isEqualTo(UserStatus.REJECTED);
        assertThat(rejected.getRejectionReason()).isEqualTo("Documentação incompleta para perfil PJ");
        assertThat(rejected.getRejectedAt()).isNotNull();
    }

    @Test
    void multipleUsersInDifferentTenants() throws Exception {
        String tenant2 = "tenant-other";
        tenantRepository.save(new Tenant(tenant2, tenant2, tenant2, TenantStatus.ACTIVE));

        // Create users in both tenants
        User user1Tenant1 = new User(TENANT_ID, "user1@t1.com", "User 1 T1", "PJ");
        User user2Tenant1 = new User(TENANT_ID, "user2@t1.com", "User 2 T1", "PJ");
        User user1Tenant2 = new User(tenant2, "user1@t2.com", "User 1 T2", "CLT");

        userRepository.save(user1Tenant1);
        userRepository.save(user2Tenant1);
        userRepository.save(user1Tenant2);

        // List pending from tenant 1
        mockMvc.perform(get("/api/users/pending")
                .header("X-Tenant-Id", TENANT_ID)
                .header("X-Correlation-Id", CORRELATION_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(2))
                .andExpect(jsonPath("$.users", hasSize(2)));

        // List pending from tenant 2
        mockMvc.perform(get("/api/users/pending")
                .header("X-Tenant-Id", tenant2)
                .header("X-Correlation-Id", CORRELATION_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(1))
                .andExpect(jsonPath("$.users", hasSize(1)));
    }

    @Test
    void createAndImportUsersPersistAuditTrail() throws Exception {
        String createPayload = """
                {
                  "email": "gestor@tenant.com",
                  "nome": "Gestor Tenant",
                  "tipo": "PJ",
                  "role": "ADMIN",
                  "externalId": "web-admin-01"
                }
                """;

        mockMvc.perform(post("/api/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", ACTOR_ID)
                        .content(createPayload))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.email").value("gestor@tenant.com"));

        String importPayload = """
                {
                  "users": [
                    {
                      "email": "importado1@tenant.com",
                      "nome": "Importado Um",
                      "tipo": "PJ",
                      "role": "FIELD_AGENT",
                      "externalId": "ad-001"
                    },
                    {
                      "email": "importado2@tenant.com",
                      "nome": "Importado Dois",
                      "tipo": "CLT",
                      "role": "OPERATOR",
                      "externalId": "ad-002"
                    }
                  ]
                }
                """;

        mockMvc.perform(post("/api/users/import")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", ACTOR_ID)
                        .content(importPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.imported").value(2));

        mockMvc.perform(get("/api/users/audit")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", ACTOR_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.count", is(3)))
                .andExpect(jsonPath("$.items[0].action").value("USER_IMPORTED_AD"))
                .andExpect(jsonPath("$.items[1].action").value("USER_IMPORTED_AD"))
                .andExpect(jsonPath("$.items[2].action").value("USER_CREATED_WEB"));

        assertThat(userAuditEntryRepository.findTop50ByTenantIdOrderByCreatedAtDesc(TENANT_ID)).hasSize(3);
    }

    @Test
    void shouldPreferMembershipRoleWhenReturningUserDetails() throws Exception {
        Tenant tenant = tenantRepository.findById(TENANT_ID).orElseThrow();

        User user = userRepository.save(new User(
                TENANT_ID,
                "membership-priority@tenant.com",
                "Membership Priority",
                "PJ",
                UserRole.ADMIN,
                UserSource.WEB_CREATED
        ));

        membershipRepository.save(new Membership(user, tenant, null, MembershipRole.OPERATOR, MembershipStatus.ACTIVE));

        mockMvc.perform(get("/api/users/{id}", user.getId())
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("membership-priority@tenant.com"))
                .andExpect(jsonPath("$.role").value("OPERATOR"));
    }

        @Test
        void shouldBackfillMembershipForLegacyUserWithoutMembership() throws Exception {
                // Usuário legado sem Membership (inserido diretamente, sem UserService)
                // Com role @Transient, o backfill usa toMembershipRole(null) = FIELD_OPERATOR
                User legacyUser = userRepository.save(new User(
                                TENANT_ID,
                                "legacy-without-membership@tenant.com",
                                "Legacy User",
                                "CLT"
                ));

                assertThat(membershipRepository.findByUser_IdAndTenant_Id(legacyUser.getId(), TENANT_ID)).isNotPresent();

                mockMvc.perform(get("/api/users/{id}", legacyUser.getId())
                                                .header("X-Tenant-Id", TENANT_ID)
                                                .header("X-Correlation-Id", CORRELATION_ID))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.email").value("legacy-without-membership@tenant.com"))
                                .andExpect(jsonPath("$.role").value("FIELD_AGENT"));

                var membership = membershipRepository.findByUser_IdAndTenant_Id(legacyUser.getId(), TENANT_ID).orElseThrow();
                assertThat(membership.getRole()).isEqualTo(MembershipRole.FIELD_OPERATOR);
                assertThat(membership.getStatus()).isEqualTo(MembershipStatus.SUSPENDED);
        }
}
