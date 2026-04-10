package com.appbackoffice.api.mobile;

import com.appbackoffice.api.auth.entity.UserCredentialEntity;
import com.appbackoffice.api.auth.repository.IdentityBindingRepository;
import com.appbackoffice.api.auth.repository.SessionRepository;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.identity.entity.Membership;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.identity.entity.MembershipStatus;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.job.dto.AssignJobRequest;
import com.appbackoffice.api.job.dto.CreateCaseRequest;
import com.appbackoffice.api.job.dto.CreateCaseResponse;
import com.appbackoffice.api.job.repository.AssignmentRepository;
import com.appbackoffice.api.job.repository.CaseRepository;
import com.appbackoffice.api.job.repository.JobRepository;
import com.appbackoffice.api.job.repository.JobTimelineRepository;
import com.appbackoffice.api.job.service.CaseService;
import com.appbackoffice.api.job.service.JobService;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserRole;
import com.appbackoffice.api.user.entity.UserSource;
import com.appbackoffice.api.user.entity.UserStatus;
import com.appbackoffice.api.user.repository.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MobileAuthJobsIntegrationTest {

    private static final String TENANT_ID = "tenant-compass-mobile-it";
    private static final String CORRELATION_ID = "corr-compass-mobile-auth-jobs";
    private static final String PASSWORD = "Senha@123";

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private TenantRepository tenantRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private MembershipRepository membershipRepository;
    @Autowired private UserCredentialRepository userCredentialRepository;
    @Autowired private IdentityBindingRepository identityBindingRepository;
    @Autowired private SessionRepository sessionRepository;
    @Autowired private CaseService caseService;
    @Autowired private JobService jobService;
    @Autowired private JobTimelineRepository timelineRepository;
    @Autowired private AssignmentRepository assignmentRepository;
    @Autowired private JobRepository jobRepository;
    @Autowired private CaseRepository caseRepository;
    @Autowired private PasswordEncoder passwordEncoder;

    private User operator;

    @BeforeEach
    void setUp() {
        cleanAll();

        Tenant tenant = tenantRepository.save(new Tenant(
                TENANT_ID,
                "compass-mobile-it",
                "Compass Mobile IT",
                TenantStatus.ACTIVE
        ));
        operator = new User(
                TENANT_ID,
                "vistoriador.compass@compass.test",
                "Vistoriador Compass",
                "PJ",
                UserRole.OPERATOR,
                UserSource.WEB_CREATED
        );
        operator.setStatus(UserStatus.APPROVED);
        operator = userRepository.save(operator);

        membershipRepository.save(new Membership(operator, tenant, null, MembershipRole.OPERATOR, MembershipStatus.ACTIVE));

        UserCredentialEntity credential = new UserCredentialEntity();
        credential.setUserId(operator.getId());
        credential.setTenantId(TENANT_ID);
        credential.setPasswordHash(passwordEncoder.encode(PASSWORD));
        userCredentialRepository.save(credential);

        CreateCaseResponse created = caseService.createCase(TENANT_ID, "platform-admin", new CreateCaseRequest(
                "COMPASS-MOBILE-001",
                "Rua Compass, 100",
                "RESIDENTIAL",
                Instant.now().plus(3, ChronoUnit.DAYS),
                "Vistoria Compass Mobile"
        ));
        jobService.assignJob(TENANT_ID, created.jobId(), new AssignJobRequest(operator.getId()), "platform-admin");
        jobService.acceptJob(TENANT_ID, created.jobId(), String.valueOf(operator.getId()));
    }

    @Test
    void shouldLoginAndListCompassMobileJobsWithMatchingBearerContext() throws Exception {
        JsonNode loginJson = login("vistoriador.compass@compass.test", PASSWORD);
        String accessToken = loginJson.get("accessToken").asText();

        var result = mockMvc.perform(get("/api/mobile/jobs")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operator.getId()))
                        .header("X-Api-Version", "v1")
                        .header("Authorization", "Bearer " + accessToken))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body).hasSize(1);
        assertThat(body.get(0).get("tenantId").asText()).isEqualTo(TENANT_ID);
        assertThat(body.get(0).get("assignedTo").asLong()).isEqualTo(operator.getId());
        assertThat(body.get(0).get("status").asText()).isEqualTo("ACCEPTED");
    }

    @Test
    void shouldRejectMobileJobsWhenBearerDoesNotMatchActorHeader() throws Exception {
        JsonNode loginJson = login("vistoriador.compass@compass.test", PASSWORD);
        String accessToken = loginJson.get("accessToken").asText();

        var result = mockMvc.perform(get("/api/mobile/jobs")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operator.getId() + 1))
                        .header("X-Api-Version", "v1")
                        .header("Authorization", "Bearer " + accessToken))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(401);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("code").asText()).isEqualTo("AUTH_CONTEXT_MISMATCH");
    }

    private JsonNode login(String email, String password) throws Exception {
        var result = mockMvc.perform(post("/auth/login")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content("""
                                {
                                  "tenantId": "%s",
                                  "email": "%s",
                                  "password": "%s",
                                  "deviceInfo": "compass-android-homolog"
                                }
                                """.formatted(TENANT_ID, email, password)))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private void cleanAll() {
        sessionRepository.deleteAll();
        identityBindingRepository.deleteAll();
        userCredentialRepository.deleteAll();
        membershipRepository.deleteAll();
        timelineRepository.deleteAll();
        assignmentRepository.deleteAll();
        jobRepository.deleteAll();
        caseRepository.deleteAll();
        userRepository.deleteAll();
        tenantRepository.deleteAll();
    }
}
