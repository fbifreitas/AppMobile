package com.appbackoffice.api.platform;

import com.appbackoffice.api.auth.repository.IdentityBindingRepository;
import com.appbackoffice.api.auth.repository.SessionRepository;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.appbackoffice.api.identity.entity.Membership;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.identity.entity.MembershipStatus;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.platform.entity.LicenseModel;
import com.appbackoffice.api.platform.entity.TenantApplicationEntity;
import com.appbackoffice.api.platform.entity.TenantApplicationStatus;
import com.appbackoffice.api.platform.entity.TenantLicenseEntity;
import com.appbackoffice.api.platform.repository.TenantApplicationRepository;
import com.appbackoffice.api.platform.repository.TenantLicenseRepository;
import com.appbackoffice.api.user.dto.CreateUserRequest;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserRole;
import com.appbackoffice.api.user.entity.UserSource;
import com.appbackoffice.api.user.repository.UserRepository;
import com.appbackoffice.api.user.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PlatformTenantIntegrationTest {

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
    private TenantApplicationRepository tenantApplicationRepository;

    @Autowired
    private TenantLicenseRepository tenantLicenseRepository;

    @Autowired
    private UserService userService;

    @BeforeEach
    void setUp() {
        sessionRepository.deleteAll();
        identityBindingRepository.deleteAll();
        userCredentialRepository.deleteAll();
        membershipRepository.deleteAll();
        userRepository.deleteAll();
        tenantApplicationRepository.deleteAll();
        tenantLicenseRepository.deleteAll();
        tenantRepository.deleteAll();

        Tenant compass = tenantRepository.save(new Tenant("tenant-compass", "compass", "Compass", TenantStatus.ACTIVE));
        tenantRepository.save(new Tenant("tenant-kaptu", "kaptu", "Kaptu", TenantStatus.ACTIVE));

        User tenantAdmin = userRepository.save(new User(
                "tenant-compass",
                "admin@compass.com",
                "Compass Admin",
                "PJ",
                UserRole.ADMIN,
                UserSource.WEB_CREATED
        ));
        membershipRepository.save(new Membership(tenantAdmin, compass, null, MembershipRole.TENANT_ADMIN, MembershipStatus.ACTIVE));

        User operator = userRepository.save(new User(
                "tenant-compass",
                "operator@compass.com",
                "Compass Operator",
                "CLT",
                UserRole.OPERATOR,
                UserSource.WEB_CREATED
        ));
        membershipRepository.save(new Membership(operator, compass, null, MembershipRole.OPERATOR, MembershipStatus.ACTIVE));

        TenantApplicationEntity app = new TenantApplicationEntity();
        app.setTenantId("tenant-compass");
        app.setAppCode("compass");
        app.setBrandName("Compass");
        app.setDisplayName("Compass Vistorias");
        app.setApplicationId("br.com.compass.vistorias");
        app.setBundleId("br.com.compass.vistorias");
        app.setFirebaseAppId("firebase-compass");
        app.setDistributionChannel("firebase");
        app.setDistributionGroup("testers-compass");
        app.setStatus(TenantApplicationStatus.READY);
        tenantApplicationRepository.save(app);

        TenantLicenseEntity license = new TenantLicenseEntity();
        license.setTenantId("tenant-compass");
        license.setLicenseModel(LicenseModel.PER_USER);
        license.setContractedSeats(3);
        license.setWarningSeats(2);
        license.setHardLimitEnforced(true);
        tenantLicenseRepository.save(license);
    }

    @Test
    void shouldListTenantsWithApplicationAndSeatSummary() throws Exception {
        var result = mockMvc.perform(get("/api/backoffice/platform/tenants")
                        .param("actorRole", "platform_admin")
                        .header("X-Correlation-Id", "corr-platform-tenants-001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(2))
                .andReturn();

        String body = result.getResponse().getContentAsString();
        assertThat(body).contains("br.com.compass.vistorias");
        assertThat(body).contains("\"consumedSeats\":2");
    }

    @Test
    void shouldReturnEmptyPlatformTenantListWhenNoTenantsExist() throws Exception {
        sessionRepository.deleteAll();
        identityBindingRepository.deleteAll();
        userCredentialRepository.deleteAll();
        membershipRepository.deleteAll();
        userRepository.deleteAll();
        tenantApplicationRepository.deleteAll();
        tenantLicenseRepository.deleteAll();
        tenantRepository.deleteAll();

        mockMvc.perform(get("/api/backoffice/platform/tenants")
                        .param("actorRole", "platform_admin")
                        .header("X-Correlation-Id", "corr-platform-tenants-empty"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(0))
                .andExpect(jsonPath("$.items").isArray());
    }

    @Test
    void shouldReturnUnauthorizedWhenListingPlatformTenantsWithoutAuthorizationContext() throws Exception {
        mockMvc.perform(get("/api/backoffice/platform/tenants")
                        .header("X-Correlation-Id", "corr-platform-tenants-unauthorized"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH_INVALID_TOKEN"));
    }

    @Test
    void shouldCreateTenantForPlatformProvisioningFlow() throws Exception {
        String payload = """
                {
                  "tenantId": "tenant-nova-empresa",
                  "slug": "nova-empresa",
                  "displayName": "Nova Empresa",
                  "status": "ACTIVE"
                }
                """;

        mockMvc.perform(post("/api/backoffice/platform/tenants")
                        .param("actorRole", "platform_admin")
                        .header("X-Correlation-Id", "corr-platform-tenants-create")
                        .contentType("application/json")
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tenantId").value("tenant-nova-empresa"))
                .andExpect(jsonPath("$.slug").value("nova-empresa"))
                .andExpect(jsonPath("$.displayName").value("Nova Empresa"))
                .andExpect(jsonPath("$.tenantStatus").value("ACTIVE"))
                .andExpect(jsonPath("$.license.consumedSeats").value(0));
    }

    @Test
    void shouldUpsertApplicationAndLicense() throws Exception {
        String applicationPayload = """
                {
                  "appCode": "compass-hml",
                  "brandName": "Compass",
                  "displayName": "Compass Homolog",
                  "applicationId": "br.com.compass.hml",
                  "bundleId": "br.com.compass.hml",
                  "firebaseAppId": "firebase-hml",
                  "distributionChannel": "firebase",
                  "distributionGroup": "homolog-compass",
                  "status": "ACTIVE"
                }
                """;

        mockMvc.perform(put("/api/backoffice/platform/tenants/tenant-kaptu/application")
                        .param("actorRole", "platform_admin")
                        .header("X-Correlation-Id", "corr-platform-tenants-002")
                        .contentType("application/json")
                        .content(applicationPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.appCode").value("compass-hml"));

        String licensePayload = """
                {
                  "licenseModel": "PER_USER",
                  "contractedSeats": 12,
                  "warningSeats": 10,
                  "hardLimitEnforced": true
                }
                """;

        mockMvc.perform(put("/api/backoffice/platform/tenants/tenant-kaptu/license")
                        .param("actorRole", "platform_admin")
                        .header("X-Correlation-Id", "corr-platform-tenants-003")
                        .contentType("application/json")
                        .content(licensePayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.contractedSeats").value(12))
                .andExpect(jsonPath("$.licenseModel").value("PER_USER"));
    }

    @Test
    void shouldBlockUserCreationWhenSeatLimitIsReached() {
        CreateUserRequest firstRequest = new CreateUserRequest(
                "third-seat@compass.com",
                "Blocked User",
                "CLT",
                null,
                null,
                null,
                null,
                "operator",
                null
        );
        CreateUserRequest secondRequest = new CreateUserRequest(
                "fourth-seat@compass.com",
                "Fourth User",
                "CLT",
                null,
                null,
                null,
                null,
                "operator",
                null
        );

        userService.createFromWeb("tenant-compass", firstRequest);

        assertThatThrownBy(() -> userService.createFromWeb("tenant-compass", secondRequest))
                .hasMessageContaining("Tenant excedeu o limite contratado de usuarios");
    }

    @Test
    void shouldProvisionInitialTenantAdminAndAllowLogin() throws Exception {
        String handoffPayload = """
                {
                  "email": "admin.homolog@kaptu.com",
                  "nome": "Admin Homolog Kaptu",
                  "tipo": "PJ",
                  "cnpj": "12345678000199",
                  "temporaryPassword": "Compass@123"
                }
                """;

        var handoffResult = mockMvc.perform(put("/api/backoffice/platform/tenants/tenant-kaptu/admin-handoff")
                        .param("actorRole", "platform_admin")
                        .header("X-Correlation-Id", "corr-platform-tenants-004")
                        .contentType("application/json")
                        .content(handoffPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tenantId").value("tenant-kaptu"))
                .andExpect(jsonPath("$.credentialProvisioned").value(true))
                .andExpect(jsonPath("$.adminUser.email").value("admin.homolog@kaptu.com"))
                .andExpect(jsonPath("$.temporaryPassword").value("Compass@123"))
                .andReturn();

        JsonNode handoffJson = objectMapper.readTree(handoffResult.getResponse().getContentAsString());
        assertThat(handoffJson.get("credentialUpdatedAt").asText()).isNotBlank();

        String loginPayload = """
                {
                  "tenantId": "tenant-kaptu",
                  "email": "admin.homolog@kaptu.com",
                  "password": "Compass@123",
                  "deviceInfo": "web-backoffice"
                }
                """;

        var loginResult = mockMvc.perform(post("/auth/login")
                        .header("X-Correlation-Id", "corr-platform-tenants-005")
                        .contentType("application/json")
                        .content(loginPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isString())
                .andReturn();

        String accessToken = objectMapper.readTree(loginResult.getResponse().getContentAsString())
                .get("accessToken")
                .asText();

        mockMvc.perform(get("/auth/me")
                        .header("X-Correlation-Id", "corr-platform-tenants-006")
                        .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tenantId").value("tenant-kaptu"))
                .andExpect(jsonPath("$.membershipRole").value("TENANT_ADMIN"));
    }
}
