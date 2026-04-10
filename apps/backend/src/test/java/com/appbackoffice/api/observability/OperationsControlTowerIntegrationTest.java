package com.appbackoffice.api.observability;

import com.appbackoffice.api.config.ConfigPackageService;
import com.appbackoffice.api.config.dto.ConfigPackagePublishRequest;
import com.appbackoffice.api.config.dto.ConfigRulesDto;
import com.appbackoffice.api.config.dto.RolloutPolicyDto;
import com.appbackoffice.api.auth.repository.IdentityBindingRepository;
import com.appbackoffice.api.auth.repository.SessionRepository;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.job.dto.AssignJobRequest;
import com.appbackoffice.api.job.dto.CreateCaseRequest;
import com.appbackoffice.api.job.dto.CreateCaseResponse;
import com.appbackoffice.api.job.repository.AssignmentRepository;
import com.appbackoffice.api.job.repository.CaseRepository;
import com.appbackoffice.api.job.repository.JobRepository;
import com.appbackoffice.api.job.repository.JobTimelineRepository;
import com.appbackoffice.api.job.service.CaseService;
import com.appbackoffice.api.job.service.JobService;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.mobile.repository.InspectionRepository;
import com.appbackoffice.api.mobile.repository.InspectionSubmissionRepository;
import com.appbackoffice.api.platform.repository.TenantApplicationRepository;
import com.appbackoffice.api.platform.repository.TenantLicenseRepository;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserStatus;
import com.appbackoffice.api.user.repository.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OperationsControlTowerIntegrationTest {

    private static final String TENANT_ID = "tenant-ops-it";
    private static final String CORRELATION_ID = "corr-ops-it-001";

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;
    @Autowired private IntegrationOperationEventRepository eventRepository;
    @Autowired private InspectionRepository inspectionRepository;
    @Autowired private InspectionSubmissionRepository inspectionSubmissionRepository;
    @Autowired private JobTimelineRepository jobTimelineRepository;
    @Autowired private AssignmentRepository assignmentRepository;
    @Autowired private JobRepository jobRepository;
    @Autowired private CaseRepository caseRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private MembershipRepository membershipRepository;
    @Autowired private TenantRepository tenantRepository;
    @Autowired private UserCredentialRepository userCredentialRepository;
    @Autowired private IdentityBindingRepository identityBindingRepository;
    @Autowired private SessionRepository sessionRepository;
    @Autowired private TenantApplicationRepository tenantApplicationRepository;
    @Autowired private TenantLicenseRepository tenantLicenseRepository;
    @Autowired private CaseService caseService;
    @Autowired private JobService jobService;
    @Autowired private ConfigPackageService configPackageService;

    private Long operatorUserId;
    private Long jobId;

    @BeforeEach
    void setUp() throws Exception {
        eventRepository.deleteAll();
        inspectionRepository.deleteAll();
        inspectionSubmissionRepository.deleteAll();
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

        tenantRepository.save(new Tenant(TENANT_ID, TENANT_ID, "Tenant Ops", TenantStatus.ACTIVE));
        User operator = userRepository.save(new User(TENANT_ID, "ops@tenant.com", "Ops Operator", "PJ"));
        operator.setStatus(UserStatus.APPROVED);
        operator = userRepository.save(operator);
        operatorUserId = operator.getId();

        CreateCaseResponse created = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-OPS-001", "Rua Ops, 10", "RESIDENTIAL", null, "Job Ops"
        ));
        jobId = created.jobId();
        jobService.assignJob(TENANT_ID, jobId, new AssignJobRequest(operatorUserId), "admin-1");
        jobService.acceptJob(TENANT_ID, jobId, String.valueOf(operatorUserId));

        submitInspection("idem-ops-001", "nonce-ops-001");
        submitInspection("idem-ops-001", "nonce-ops-002");
        validateIntakeAndGenerateReport();

        configPackageService.publish(new ConfigPackagePublishRequest(
                "9001",
                "tenant_admin",
                "tenant",
                TENANT_ID,
                null,
                new RolloutPolicyDto("immediate", null, null, null),
                new ConfigRulesDto(Boolean.TRUE, 4, 8, Boolean.FALSE, "tenant-default", "stable", null)
        ));
    }

    @AfterEach
    void tearDown() {
        eventRepository.deleteAll();
        inspectionRepository.deleteAll();
        inspectionSubmissionRepository.deleteAll();
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

    @Test
    void shouldExposeControlTowerDashboardAndRunRetention() throws Exception {
        insertExpiredEvent();

        var dashboardResult = mockMvc.perform(get("/api/backoffice/operations/control-tower")
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(dashboardResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode dashboardBody = objectMapper.readTree(dashboardResult.getResponse().getContentAsString());
        assertThat(dashboardBody.at("/overview/totalRequests24h").asInt()).isGreaterThan(0);
        assertThat(dashboardBody.at("/overview/retryOrDuplicateCount24h").asInt()).isGreaterThan(0);
        assertThat(dashboardBody.at("/overview/reportsReadyForSign").asInt()).isEqualTo(1);
        assertThat(dashboardBody.at("/overview/pendingConfigApprovals").asInt()).isEqualTo(1);
        assertThat(dashboardBody.at("/endpointMetrics/0/endpointKey").asText()).isNotBlank();
        assertThat(dashboardBody.toString()).contains("mobile.inspections.finalized");
        assertThat(dashboardBody.toString()).contains("DUPLICATE_SUBMISSIONS");
        assertThat(dashboardBody.toString()).contains("READY");

        var retentionResult = mockMvc.perform(post("/api/backoffice/operations/control-tower/retention/run")
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(retentionResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode retentionBody = objectMapper.readTree(retentionResult.getResponse().getContentAsString());
        assertThat(retentionBody.get("deletedEvents").asInt()).isGreaterThanOrEqualTo(1);
    }

    private void submitInspection(String idempotencyKey, String nonce) throws Exception {
        mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", idempotencyKey)
                        .header("X-Request-Timestamp", Instant.now().toString())
                        .header("X-Request-Nonce", nonce)
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content("""
                                {
                                  "exportedAt": "2026-04-08T15:00:00Z",
                                  "job": {"id": "%s", "titulo": "Job Ops"},
                                  "step1": {},
                                  "step2": {},
                                  "step2Config": {},
                                  "review": {"photos": 4}
                                }
                                """.formatted(jobId)))
                .andReturn();
    }

    private void validateIntakeAndGenerateReport() throws Exception {
        var listResult = mockMvc.perform(get("/api/backoffice/valuation/processes")
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();
        JsonNode listBody = objectMapper.readTree(listResult.getResponse().getContentAsString());
        long processId = listBody.at("/items/0/id").asLong();

        mockMvc.perform(post("/api/backoffice/valuation/processes/{processId}/validate-intake", processId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .header("X-Actor-Id", "9001")
                        .contentType("application/json")
                        .content("""
                                {
                                  "result": "VALIDATED",
                                  "issues": {"missingPhotos": 0},
                                  "notes": "Operational intake validated"
                                }
                                """))
                .andReturn();

        var reportGenerationResult = mockMvc.perform(post("/api/backoffice/reports/{valuationProcessId}/generate", processId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .header("X-Actor-Id", "reviewer-1"))
                .andReturn();
        JsonNode reportBody = objectMapper.readTree(reportGenerationResult.getResponse().getContentAsString());
        long reportId = reportBody.get("id").asLong();

        mockMvc.perform(post("/api/backoffice/reports/{reportId}/review", reportId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .header("X-Actor-Id", "tech-reviewer-1")
                        .contentType("application/json")
                        .content("""
                                {
                                  "action": "APPROVE",
                                  "notes": "Ready for sign"
                                }
                                """))
                .andReturn();
    }

    private void insertExpiredEvent() {
        jdbcTemplate.update("""
                INSERT INTO integration_operation_events (
                    tenant_id, channel, event_type, endpoint_key, outcome, summary, occurred_at, retention_until
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                TENANT_ID,
                "BACKOFFICE",
                "HTTP_INTERACTION",
                "backoffice.legacy",
                "SUCCESS",
                "Expired synthetic event",
                Timestamp.from(Instant.now().minus(45, ChronoUnit.DAYS)),
                Timestamp.from(Instant.now().minus(10, ChronoUnit.DAYS))
        );
    }
}
