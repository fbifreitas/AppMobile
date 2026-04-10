package com.appbackoffice.api.compass;

import com.appbackoffice.api.auth.entity.UserCredentialEntity;
import com.appbackoffice.api.auth.repository.IdentityBindingRepository;
import com.appbackoffice.api.auth.repository.SessionRepository;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.config.ConfigAuditEntryRepository;
import com.appbackoffice.api.config.ConfigPackageRepository;
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
import com.appbackoffice.api.mobile.repository.CheckinSectionRepository;
import com.appbackoffice.api.mobile.repository.InspectionRepository;
import com.appbackoffice.api.mobile.repository.InspectionSubmissionRepository;
import com.appbackoffice.api.observability.IntegrationOperationEventRepository;
import com.appbackoffice.api.platform.repository.TenantApplicationRepository;
import com.appbackoffice.api.platform.repository.TenantLicenseRepository;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserRole;
import com.appbackoffice.api.user.entity.UserSource;
import com.appbackoffice.api.user.entity.UserStatus;
import com.appbackoffice.api.user.repository.UserRepository;
import com.appbackoffice.api.valuation.repository.IntakeValidationRepository;
import com.appbackoffice.api.valuation.repository.ReportRepository;
import com.appbackoffice.api.valuation.repository.ValuationProcessRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CompassOperationEndToEndIntegrationTest {

    private static final String TENANT_ID = "tenant-compass-e2e";
    private static final String CORRELATION_ID = "corr-compass-e2e-001";
    private static final String PASSWORD = "Senha@123";

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private TenantRepository tenantRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private MembershipRepository membershipRepository;
    @Autowired private TenantApplicationRepository tenantApplicationRepository;
    @Autowired private TenantLicenseRepository tenantLicenseRepository;
    @Autowired private UserCredentialRepository userCredentialRepository;
    @Autowired private IdentityBindingRepository identityBindingRepository;
    @Autowired private SessionRepository sessionRepository;
    @Autowired private CaseService caseService;
    @Autowired private JobService jobService;
    @Autowired private JobTimelineRepository jobTimelineRepository;
    @Autowired private AssignmentRepository assignmentRepository;
    @Autowired private JobRepository jobRepository;
    @Autowired private CaseRepository caseRepository;
    @Autowired private InspectionRepository inspectionRepository;
    @Autowired private InspectionSubmissionRepository inspectionSubmissionRepository;
    @Autowired private CheckinSectionRepository checkinSectionRepository;
    @Autowired private ConfigAuditEntryRepository configAuditEntryRepository;
    @Autowired private ConfigPackageRepository configPackageRepository;
    @Autowired private ValuationProcessRepository valuationProcessRepository;
    @Autowired private IntakeValidationRepository intakeValidationRepository;
    @Autowired private ReportRepository reportRepository;
    @Autowired private IntegrationOperationEventRepository eventRepository;
    @Autowired private PasswordEncoder passwordEncoder;

    private User operator;
    private Long jobId;

    @BeforeEach
    void setUp() {
        cleanAll();

        Tenant tenant = tenantRepository.save(new Tenant(
                TENANT_ID,
                "compass-e2e",
                "Compass E2E",
                TenantStatus.ACTIVE
        ));
        operator = new User(
                TENANT_ID,
                "campo.compass@compass.test",
                "Campo Compass",
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
                "COMPASS-E2E-001",
                "Rua Compass E2E, 100",
                "RESIDENTIAL",
                null,
                "Vistoria Compass E2E"
        ));
        jobId = created.jobId();
        jobService.assignJob(TENANT_ID, jobId, new AssignJobRequest(operator.getId()), "platform-admin");
        jobService.acceptJob(TENANT_ID, jobId, String.valueOf(operator.getId()));
    }

    @AfterEach
    void tearDown() {
        cleanAll();
    }

    @Test
    void shouldOperateCompassFromConfigToReportAndControlTower() throws Exception {
        JsonNode loginJson = login();
        String accessToken = loginJson.get("accessToken").asText();

        String packageId = publishAndApproveConfig();
        assertMobileConfig(accessToken, packageId);
        assertMobileJobs(accessToken);

        submitInspection(accessToken);
        long inspectionId = assertBackofficeReceivesInspection();

        long valuationProcessId = assertValuationProcessCreated();
        validateIntake(valuationProcessId);
        long reportId = generateAndReviewReport(valuationProcessId);
        assertControlTowerTracksOperation(reportId);
    }

    private JsonNode login() throws Exception {
        var result = mockMvc.perform(post("/auth/login")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .contentType("application/json")
                        .content("""
                                {
                                  "tenantId": "%s",
                                  "email": "campo.compass@compass.test",
                                  "password": "%s",
                                  "deviceInfo": "compass-e2e-android"
                                }
                                """.formatted(TENANT_ID, PASSWORD)))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private String publishAndApproveConfig() throws Exception {
        var publishResult = mockMvc.perform(post("/api/backoffice/config/packages")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .contentType("application/json")
                        .content("""
                                {
                                  "actorId": "admin-compass",
                                  "actorRole": "tenant_admin",
                                  "scope": "tenant",
                                  "tenantId": "%s",
                                  "rollout": {
                                    "activation": "immediate"
                                  },
                                  "rules": {
                                    "cameraMinPhotos": 2,
                                    "cameraMaxPhotos": 8,
                                    "enableVoiceCommands": true,
                                    "requireBiometric": false,
                                    "theme": "compass-field"
                                  }
                                }
                                """.formatted(TENANT_ID)))
                .andReturn();

        assertThat(publishResult.getResponse().getStatus()).isEqualTo(201);
        String packageId = objectMapper.readTree(publishResult.getResponse().getContentAsString())
                .at("/result/created/id")
                .asText();

        var approveResult = mockMvc.perform(post("/api/backoffice/config/packages/approve")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "TENANT_ADMIN")
                        .contentType("application/json")
                        .content("""
                                {
                                  "packageId": "%s",
                                  "tenantId": "%s",
                                  "actorId": "admin-compass",
                                  "actorRole": "tenant_admin"
                                }
                                """.formatted(packageId, TENANT_ID)))
                .andReturn();

        assertThat(approveResult.getResponse().getStatus()).isEqualTo(200);
        return packageId;
    }

    private void assertMobileConfig(String accessToken, String packageId) throws Exception {
        var result = mockMvc.perform(get("/api/mobile/checkin-config")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operator.getId()))
                        .header("X-Api-Version", "v1")
                        .header("Authorization", "Bearer " + accessToken)
                        .queryParam("tipoImovel", "RESIDENTIAL"))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.at("/step2/photoPolicy/min").asInt()).isEqualTo(2);
        assertThat(body.at("/step2/photoPolicy/max").asInt()).isEqualTo(8);
        assertThat(body.at("/step2/featureFlags/enableVoiceCommands").asBoolean()).isTrue();
        assertThat(body.get("compatibilityNotes").toString()).contains(packageId);
    }

    private void assertMobileJobs(String accessToken) throws Exception {
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
        assertThat(body.get(0).get("id").asLong()).isEqualTo(jobId);
        assertThat(body.get(0).get("status").asText()).isEqualTo("ACCEPTED");
    }

    private void submitInspection(String accessToken) throws Exception {
        var result = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .contentType("application/json")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operator.getId()))
                        .header("X-Api-Version", "v1")
                        .header("X-Idempotency-Key", "idem-compass-e2e-001")
                        .header("X-Request-Timestamp", Instant.now().toString())
                        .header("X-Request-Nonce", "nonce-compass-e2e-001")
                        .header("Authorization", "Bearer " + accessToken)
                        .content("""
                                {
                                  "exportedAt": "2026-04-10T10:00:00Z",
                                  "job": {"id": "%s", "titulo": "Vistoria Compass E2E"},
                                  "step1": {"tipoImovel": "RESIDENTIAL"},
                                  "step2": {"photos": 4},
                                  "step2Config": {"minFotos": 2, "maxFotos": 8},
                                  "review": {"photos": 4, "status": "complete"}
                                }
                                """.formatted(jobId)))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(202);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("status").asText()).isEqualTo("SUBMITTED");
        assertThat(body.get("jobId").asLong()).isEqualTo(jobId);
        assertThat(body.get("protocolId").asText()).startsWith("INS-");
    }

    private long assertBackofficeReceivesInspection() throws Exception {
        var listResult = mockMvc.perform(get("/api/backoffice/inspections")
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(listResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode listBody = objectMapper.readTree(listResult.getResponse().getContentAsString());
        assertThat(listBody.get("total").asInt()).isEqualTo(1);
        long inspectionId = listBody.at("/items/0/id").asLong();
        assertThat(listBody.at("/items/0/id").asLong()).isEqualTo(inspectionId);
        assertThat(listBody.at("/items/0/jobId").asLong()).isEqualTo(jobId);

        var detailResult = mockMvc.perform(get("/api/backoffice/inspections/{inspectionId}", inspectionId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "AUDITOR"))
                .andReturn();

        assertThat(detailResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode detailBody = objectMapper.readTree(detailResult.getResponse().getContentAsString());
        assertThat(detailBody.get("tenantId").asText()).isEqualTo(TENANT_ID);
        assertThat(detailBody.get("jobId").asLong()).isEqualTo(jobId);
        return inspectionId;
    }

    private long assertValuationProcessCreated() throws Exception {
        var result = mockMvc.perform(get("/api/backoffice/valuation/processes")
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("total").asInt()).isEqualTo(1);
        assertThat(body.at("/items/0/status").asText()).isEqualTo("PENDING_INTAKE");
        return body.at("/items/0/id").asLong();
    }

    private void validateIntake(long processId) throws Exception {
        var result = mockMvc.perform(post("/api/backoffice/valuation/processes/{processId}/validate-intake", processId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .header("X-Actor-Id", "admin-compass")
                        .contentType("application/json")
                        .content("""
                                {
                                  "result": "VALIDATED",
                                  "issues": {"missingPhotos": 0},
                                  "notes": "Compass intake validated"
                                }
                                """))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("status").asText()).isEqualTo("INTAKE_VALIDATED");
    }

    private long generateAndReviewReport(long processId) throws Exception {
        var generation = mockMvc.perform(post("/api/backoffice/reports/{valuationProcessId}/generate", processId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .header("X-Actor-Id", "admin-compass"))
                .andReturn();

        assertThat(generation.getResponse().getStatus()).isEqualTo(200);
        JsonNode generationBody = objectMapper.readTree(generation.getResponse().getContentAsString());
        long reportId = generationBody.get("id").asLong();
        assertThat(generationBody.get("status").asText()).isEqualTo("GENERATED");
        assertThat(generationBody.at("/content/jobId").asLong()).isEqualTo(jobId);

        var review = mockMvc.perform(post("/api/backoffice/reports/{reportId}/review", reportId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .header("X-Actor-Id", "admin-compass")
                        .contentType("application/json")
                        .content("""
                                {
                                  "action": "APPROVE",
                                  "notes": "Compass ready for sign"
                                }
                                """))
                .andReturn();

        assertThat(review.getResponse().getStatus()).isEqualTo(200);
        JsonNode reviewBody = objectMapper.readTree(review.getResponse().getContentAsString());
        assertThat(reviewBody.get("status").asText()).isEqualTo("READY_FOR_SIGN");
        return reportId;
    }

    private void assertControlTowerTracksOperation(long reportId) throws Exception {
        var result = mockMvc.perform(get("/api/backoffice/operations/control-tower")
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.at("/overview/totalRequests24h").asInt()).isGreaterThan(0);
        assertThat(body.at("/overview/reportsReadyForSign").asInt()).isEqualTo(1);
        assertThat(body.toString()).contains("mobile.inspections.finalized");
        assertThat(reportId).isPositive();
    }

    private void cleanAll() {
        eventRepository.deleteAll();
        reportRepository.deleteAll();
        intakeValidationRepository.deleteAll();
        valuationProcessRepository.deleteAll();
        inspectionRepository.deleteAll();
        inspectionSubmissionRepository.deleteAll();
        configAuditEntryRepository.deleteAll();
        configPackageRepository.deleteAll();
        checkinSectionRepository.deleteAll();
        jobTimelineRepository.deleteAll();
        assignmentRepository.deleteAll();
        jobRepository.deleteAll();
        caseRepository.deleteAll();
        sessionRepository.deleteAll();
        identityBindingRepository.deleteAll();
        userCredentialRepository.deleteAll();
        membershipRepository.deleteAll();
        userRepository.deleteAll();
        tenantApplicationRepository.deleteAll();
        tenantLicenseRepository.deleteAll();
        tenantRepository.deleteAll();
    }
}
