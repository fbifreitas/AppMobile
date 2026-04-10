package com.appbackoffice.api.valuation;

import com.appbackoffice.api.auth.repository.IdentityBindingRepository;
import com.appbackoffice.api.auth.repository.SessionRepository;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
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
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ValuationReportBackofficeIntegrationTest {

    private static final String TENANT_ID = "tenant-valuation-it";
    private static final String CORRELATION_ID = "corr-valuation-it-001";

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private InspectionRepository inspectionRepository;
    @Autowired private InspectionSubmissionRepository inspectionSubmissionRepository;
    @Autowired private JobTimelineRepository jobTimelineRepository;
    @Autowired private AssignmentRepository assignmentRepository;
    @Autowired private JobRepository jobRepository;
    @Autowired private CaseRepository caseRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private MembershipRepository membershipRepository;
    @Autowired private UserCredentialRepository userCredentialRepository;
    @Autowired private IdentityBindingRepository identityBindingRepository;
    @Autowired private SessionRepository sessionRepository;
    @Autowired private TenantRepository tenantRepository;
    @Autowired private TenantApplicationRepository tenantApplicationRepository;
    @Autowired private TenantLicenseRepository tenantLicenseRepository;
    @Autowired private CaseService caseService;
    @Autowired private JobService jobService;

    private Long operatorUserId;
    private Long jobId;

    @BeforeEach
    void setUp() throws Exception {
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

        tenantRepository.save(new Tenant(TENANT_ID, TENANT_ID, "Tenant Valuation", TenantStatus.ACTIVE));
        User operator = userRepository.save(new User(TENANT_ID, "valuation@tenant.com", "Valuation Operator", "PJ"));
        operator.setStatus(UserStatus.APPROVED);
        operator = userRepository.save(operator);
        operatorUserId = operator.getId();

        CreateCaseResponse created = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-VALUATION-001", "Rua Valuation, 100", "RESIDENTIAL", null, "Job Valuation"
        ));
        jobId = created.jobId();
        jobService.assignJob(TENANT_ID, jobId, new AssignJobRequest(operatorUserId), "admin-1");
        jobService.acceptJob(TENANT_ID, jobId, String.valueOf(operatorUserId));

        submitInspection();
    }

    @AfterEach
    void tearDown() {
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
    void shouldRunValuationAndReportFlowFromSubmittedInspection() throws Exception {
        var listResult = mockMvc.perform(get("/api/backoffice/valuation/processes")
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(listResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode listBody = objectMapper.readTree(listResult.getResponse().getContentAsString());
        assertThat(listBody.get("total").asInt()).isEqualTo(1);
        Long processId = listBody.at("/items/0/id").asLong();
        assertThat(listBody.at("/items/0/status").asText()).isEqualTo("PENDING_INTAKE");

        var validationResult = mockMvc.perform(post("/api/backoffice/valuation/processes/{processId}/validate-intake", processId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .header("X-Actor-Id", "9001")
                        .contentType("application/json")
                        .content("""
                                {
                                  "result": "VALIDATED",
                                  "issues": {"missingPhotos": 0},
                                  "notes": "Intake validated"
                                }
                                """))
                .andReturn();

        assertThat(validationResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode validationBody = objectMapper.readTree(validationResult.getResponse().getContentAsString());
        assertThat(validationBody.get("status").asText()).isEqualTo("INTAKE_VALIDATED");
        assertThat(validationBody.at("/latestIntakeValidation/result").asText()).isEqualTo("VALIDATED");

        var reportGenerationResult = mockMvc.perform(post("/api/backoffice/reports/{valuationProcessId}/generate", processId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .header("X-Actor-Id", "reviewer-1"))
                .andReturn();

        assertThat(reportGenerationResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode reportBody = objectMapper.readTree(reportGenerationResult.getResponse().getContentAsString());
        Long reportId = reportBody.get("id").asLong();
        assertThat(reportBody.get("status").asText()).isEqualTo("GENERATED");
        assertThat(reportBody.at("/content/inspectionId").asLong()).isPositive();
        assertThat(reportBody.at("/content/jobId").asLong()).isEqualTo(jobId);

        var reviewResult = mockMvc.perform(post("/api/backoffice/reports/{reportId}/review", reportId)
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

        assertThat(reviewResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode reviewBody = objectMapper.readTree(reviewResult.getResponse().getContentAsString());
        assertThat(reviewBody.get("status").asText()).isEqualTo("READY_FOR_SIGN");

        var processDetailResult = mockMvc.perform(get("/api/backoffice/valuation/processes/{processId}", processId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "AUDITOR"))
                .andReturn();

        assertThat(processDetailResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode processBody = objectMapper.readTree(processDetailResult.getResponse().getContentAsString());
        assertThat(processBody.get("status").asText()).isEqualTo("READY_FOR_SIGN");
        assertThat(processBody.get("reportId").asLong()).isEqualTo(reportId);
    }

    private void submitInspection() throws Exception {
        mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", "idem-valuation-001")
                        .header("X-Request-Timestamp", Instant.now().toString())
                        .header("X-Request-Nonce", "nonce-valuation-001")
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content("""
                                {
                                  \"exportedAt\": \"2026-04-08T15:00:00Z\",
                                  \"job\": {\"id\": \"%s\", \"titulo\": \"Job Valuation\"},
                                  \"step1\": {},
                                  \"step2\": {},
                                  \"step2Config\": {},
                                  \"review\": {\"photos\": 4}
                                }
                                """.formatted(jobId)))
                .andReturn();
    }
}
