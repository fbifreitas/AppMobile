package com.appbackoffice.api.auth;

import com.appbackoffice.api.auth.entity.UserCredentialEntity;
import com.appbackoffice.api.auth.repository.IdentityBindingRepository;
import com.appbackoffice.api.auth.repository.FirstAccessOtpRepository;
import com.appbackoffice.api.auth.repository.SessionRepository;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.identity.entity.Membership;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.identity.entity.MembershipStatus;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.platform.entity.TenantApplicationEntity;
import com.appbackoffice.api.platform.entity.TenantApplicationStatus;
import com.appbackoffice.api.platform.repository.TenantApplicationRepository;
import com.appbackoffice.api.platform.repository.TenantLicenseRepository;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserRole;
import com.appbackoffice.api.user.entity.UserSource;
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

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthIntegrationTest {

    private static final String TENANT_ID = "tenant-auth-it";
    private static final String CORRELATION_ID = "corr-auth-it-001";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TenantRepository tenantRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private MembershipRepository membershipRepository;

    @Autowired
    private SessionRepository sessionRepository;

    @Autowired
    private UserCredentialRepository userCredentialRepository;

    @Autowired
    private IdentityBindingRepository identityBindingRepository;

    @Autowired
    private FirstAccessOtpRepository firstAccessOtpRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private TenantApplicationRepository tenantApplicationRepository;

    @Autowired
    private TenantLicenseRepository tenantLicenseRepository;

    @BeforeEach
    void setUp() {
        sessionRepository.deleteAll();
        identityBindingRepository.deleteAll();
        firstAccessOtpRepository.deleteAll();
        tenantApplicationRepository.deleteAll();
        tenantLicenseRepository.deleteAll();
        userCredentialRepository.deleteAll();
        membershipRepository.deleteAll();
        userRepository.deleteAll();
        tenantRepository.deleteAll();

        Tenant tenant = tenantRepository.save(new Tenant(TENANT_ID, TENANT_ID, "Tenant Auth", TenantStatus.ACTIVE));
        User user = userRepository.save(new User(
                TENANT_ID,
                "auth.user@tenant.com",
                "Auth User",
                "CLT",
                UserRole.OPERATOR,
                UserSource.WEB_CREATED
        ));

        membershipRepository.save(new Membership(user, tenant, null, MembershipRole.OPERATOR, MembershipStatus.ACTIVE));

        UserCredentialEntity credential = new UserCredentialEntity();
        credential.setUserId(user.getId());
        credential.setTenantId(TENANT_ID);
        credential.setPasswordHash(passwordEncoder.encode("Senha@123"));
        userCredentialRepository.save(credential);

        TenantApplicationEntity application = new TenantApplicationEntity();
        application.setTenantId(TENANT_ID);
        application.setAppCode("compass");
        application.setBrandName("Compass");
        application.setDisplayName("Compass Avaliacoes");
        application.setApplicationId("com.app.compass");
        application.setBundleId("com.app.compass");
        application.setStatus(TenantApplicationStatus.ACTIVE);
        tenantApplicationRepository.save(application);
    }

    @Test
    void shouldLoginAndReturnAuthMe() throws Exception {
        String loginPayload = """
                {
                  "tenantId": "tenant-auth-it",
                  "email": "auth.user@tenant.com",
                  "password": "Senha@123",
                  "deviceInfo": "android-emulator"
                }
                """;

        var loginResult = mockMvc.perform(post("/auth/login")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content(loginPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andReturn();

        JsonNode loginJson = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        String accessToken = loginJson.get("accessToken").asText();

        mockMvc.perform(get("/auth/me")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tenantId").value(TENANT_ID))
                .andExpect(jsonPath("$.email").value("auth.user@tenant.com"))
                .andExpect(jsonPath("$.membershipRole").value("OPERATOR"));

        assertThat(identityBindingRepository.findAll()).hasSize(1);
    }

    @Test
    void shouldRefreshAccessToken() throws Exception {
        String loginPayload = """
                {
                  "tenantId": "tenant-auth-it",
                  "email": "auth.user@tenant.com",
                  "password": "Senha@123"
                }
                """;

        var loginResult = mockMvc.perform(post("/auth/login")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content(loginPayload))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode loginJson = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        String refreshToken = loginJson.get("refreshToken").asText();

        String refreshPayload = """
                {
                  "refreshToken": "%s"
                }
                """.formatted(refreshToken);

        mockMvc.perform(post("/auth/refresh")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content(refreshPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isString())
                .andExpect(jsonPath("$.refreshToken").isString());
    }

    @Test
    void shouldRevokeRefreshTokenOnLogout() throws Exception {
        String loginPayload = """
                {
                  "tenantId": "tenant-auth-it",
                  "email": "auth.user@tenant.com",
                  "password": "Senha@123"
                }
                """;

        var loginResult = mockMvc.perform(post("/auth/login")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content(loginPayload))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode loginJson = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        String refreshToken = loginJson.get("refreshToken").asText();

        String logoutPayload = """
                {
                  "refreshToken": "%s"
                }
                """.formatted(refreshToken);

        mockMvc.perform(post("/auth/logout")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content(logoutPayload))
                .andExpect(status().isOk());

        String refreshPayload = """
                {
                  "refreshToken": "%s"
                }
                """.formatted(refreshToken);

        mockMvc.perform(post("/auth/refresh")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content(refreshPayload))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH_INVALID_TOKEN"));
    }

    @Test
    void shouldLockAfterSixthFailedAttempt() throws Exception {
        String invalidPayload = """
                {
                  "tenantId": "tenant-auth-it",
                  "email": "auth.user@tenant.com",
                  "password": "SenhaErrada"
                }
                """;

        for (int i = 0; i < 5; i++) {
            mockMvc.perform(post("/auth/login")
                            .header("X-Correlation-Id", CORRELATION_ID)
                            .contentType("application/json")
                            .content(invalidPayload))
                    .andExpect(status().isUnauthorized());
        }

        mockMvc.perform(post("/auth/login")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content(invalidPayload))
                .andExpect(status().isLocked())
                .andExpect(jsonPath("$.code").value("AUTH_ACCOUNT_LOCKED"));
    }

    @Test
    void shouldCompleteCompassFirstAccessWithOtpBeforePasswordLogin() throws Exception {
        User compassUser = new User(
                TENANT_ID,
                "compass.operator@tenant.com",
                "Compass Operator",
                "CLT",
                UserRole.OPERATOR,
                UserSource.WEB_CREATED
        );
        compassUser.setCpf("12345678901");
        compassUser.setBirthDate(LocalDate.of(1990, 5, 20));
        compassUser.setExternalId("COMPASS-001");
        compassUser.setPhone("+55 11 99999-1234");
        compassUser = userRepository.save(compassUser);
        Tenant tenant = tenantRepository.findById(TENANT_ID).orElseThrow();
        membershipRepository.save(new Membership(compassUser, tenant, null, MembershipRole.OPERATOR, MembershipStatus.ACTIVE));

        String startPayload = """
                {
                  "tenantId": "tenant-auth-it",
                  "cpf": "123.456.789-01",
                  "birthDate": "1990-05-20",
                  "identifier": "COMPASS-001"
                }
                """;

        var startResult = mockMvc.perform(post("/auth/first-access/start")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content(startPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.challengeId").isString())
                .andExpect(jsonPath("$.deliveryHint").value("Codigo enviado ao telefone cadastrado final 1234."))
                .andExpect(jsonPath("$.debugOtp").isString())
                .andReturn();

        JsonNode startJson = objectMapper.readTree(startResult.getResponse().getContentAsString());
        String challengeId = startJson.get("challengeId").asText();
        String otp = startJson.get("debugOtp").asText();

        String completePayload = """
                {
                  "tenantId": "tenant-auth-it",
                  "challengeId": "%s",
                  "otp": "%s",
                  "newPassword": "Compass@123",
                  "deviceInfo": "android-compass"
                }
                """.formatted(challengeId, otp);

        mockMvc.perform(post("/auth/first-access/complete")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content(completePayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.accessToken").isString())
                .andExpect(jsonPath("$.refreshToken").isString());

        String loginPayload = """
                {
                  "tenantId": "tenant-auth-it",
                  "email": "compass.operator@tenant.com",
                  "password": "Compass@123"
                }
                """;

        mockMvc.perform(post("/auth/login")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content(loginPayload))
                .andExpect(status().isOk());
    }

    @Test
    void shouldReturnNeutralFirstAccessStartForUnknownCompassUser() throws Exception {
        String startPayload = """
                {
                  "tenantId": "tenant-auth-it",
                  "cpf": "00000000000",
                  "birthDate": "1990-05-20",
                  "identifier": "UNKNOWN"
                }
                """;

        mockMvc.perform(post("/auth/first-access/start")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content(startPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.challengeId").isString())
                .andExpect(jsonPath("$.deliveryHint").value("Se os dados estiverem corretos, enviaremos um codigo ao contato cadastrado."))
                .andExpect(jsonPath("$.debugOtp").doesNotExist());
    }

    @Test
    void shouldReturnAuthenticatedOnboardingPendingStatus() throws Exception {
        String loginPayload = """
                {
                  "tenantId": "tenant-auth-it",
                  "email": "auth.user@tenant.com",
                  "password": "Senha@123"
                }
                """;

        var loginResult = mockMvc.perform(post("/auth/login")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content(loginPayload))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode loginJson = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        String accessToken = loginJson.get("accessToken").asText();

        mockMvc.perform(get("/auth/onboarding-pending")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tenantId").value(TENANT_ID))
                .andExpect(jsonPath("$.appCode").value("compass"))
                .andExpect(jsonPath("$.onboardingPolicy").value("corporate_first_access"))
                .andExpect(jsonPath("$.pendingSteps[0]").value("identity_validation"));
    }
}
