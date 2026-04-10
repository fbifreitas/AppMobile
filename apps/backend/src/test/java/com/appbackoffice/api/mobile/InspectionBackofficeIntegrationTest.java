package com.appbackoffice.api.mobile;

import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
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
class InspectionBackofficeIntegrationTest {

    private static final String TENANT_ID = "tenant-inspections-web-it";
    private static final String CORRELATION_ID = "corr-inspections-web-it-001";

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private InspectionRepository inspectionRepository;
    @Autowired private InspectionSubmissionRepository inspectionSubmissionRepository;
    @Autowired private JobTimelineRepository jobTimelineRepository;
    @Autowired private AssignmentRepository assignmentRepository;
    @Autowired private JobRepository jobRepository;
    @Autowired private CaseRepository caseRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private TenantRepository tenantRepository;
    @Autowired private TenantApplicationRepository tenantApplicationRepository;
    @Autowired private TenantLicenseRepository tenantLicenseRepository;
    @Autowired private CaseService caseService;
    @Autowired private JobService jobService;

    private Long operatorUserId;
    private Long firstJobId;
    private Long secondJobId;

    @BeforeEach
    void setUp() throws Exception {
        inspectionRepository.deleteAll();
        inspectionSubmissionRepository.deleteAll();
        jobTimelineRepository.deleteAll();
        assignmentRepository.deleteAll();
        jobRepository.deleteAll();
        caseRepository.deleteAll();
        userRepository.deleteAll();
        tenantApplicationRepository.deleteAll();
        tenantLicenseRepository.deleteAll();
        tenantRepository.deleteAll();

        tenantRepository.save(new Tenant(TENANT_ID, TENANT_ID, "Tenant Web Inspections", TenantStatus.ACTIVE));
        User operator = userRepository.save(new User(TENANT_ID, "inspection@tenant.com", "Operador Vistoria", "PJ"));
        operator.setStatus(UserStatus.APPROVED);
        operator = userRepository.save(operator);
        operatorUserId = operator.getId();

        firstJobId = createAcceptedJob("CASE-WEB-001", "Job Web 1");
        secondJobId = createAcceptedJob("CASE-WEB-002", "Job Web 2");

        submitInspection(firstJobId, "idem-web-001", "2026-04-03T13:00:00Z");
        submitInspection(secondJobId, "idem-web-002", "2026-04-03T14:00:00Z");
    }

    @AfterEach
    void tearDown() {
        inspectionRepository.deleteAll();
        inspectionSubmissionRepository.deleteAll();
        jobTimelineRepository.deleteAll();
        assignmentRepository.deleteAll();
        jobRepository.deleteAll();
        caseRepository.deleteAll();
        userRepository.deleteAll();
        tenantApplicationRepository.deleteAll();
        tenantLicenseRepository.deleteAll();
        tenantRepository.deleteAll();
    }

    @Test
    void shouldListInspectionsWithPaginationAndFilters() throws Exception {
        var result = mockMvc.perform(get("/api/backoffice/inspections")
                        .queryParam("tenantId", TENANT_ID)
                        .queryParam("status", "SUBMITTED")
                        .queryParam("page", "0")
                        .queryParam("size", "1")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("total").asInt()).isEqualTo(2);
        assertThat(body.get("page").asInt()).isEqualTo(0);
        assertThat(body.get("size").asInt()).isEqualTo(1);
        assertThat(body.withArray("items").size()).isEqualTo(1);
        assertThat(body.at("/items/0/status").asText()).isEqualTo("SUBMITTED");
    }

    @Test
    void shouldReturnInspectionDetail() throws Exception {
        Long inspectionId = inspectionRepository.findAll().getFirst().getId();

        var result = mockMvc.perform(get("/api/backoffice/inspections/{inspectionId}", inspectionId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "AUDITOR"))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("id").asLong()).isEqualTo(inspectionId);
        assertThat(body.get("tenantId").asText()).isEqualTo(TENANT_ID);
        assertThat(body.get("status").asText()).isEqualTo("SUBMITTED");
        assertThat(body.at("/payload/job/id").asText()).isNotBlank();
    }

    private Long createAcceptedJob(String caseNumber, String title) {
        CreateCaseResponse created = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                caseNumber, "Rua Web, 123", "RESIDENTIAL", null, title
        ));
        jobService.assignJob(TENANT_ID, created.jobId(), new AssignJobRequest(operatorUserId), "admin-1");
        jobService.acceptJob(TENANT_ID, created.jobId(), String.valueOf(operatorUserId));
        return created.jobId();
    }

    private void submitInspection(Long jobId, String idempotencyKey, String exportedAt) throws Exception {
        mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", idempotencyKey)
                        .header("X-Request-Timestamp", Instant.now().toString())
                        .header("X-Request-Nonce", "nonce-" + idempotencyKey)
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content("""
                                {
                                  \"exportedAt\": \"%s\",
                                  \"job\": {\"id\": \"%s\", \"titulo\": \"Job Web\"},
                                  \"step1\": {},
                                  \"step2\": {},
                                  \"step2Config\": {},
                                  \"review\": {\"photos\": 2}
                                }
                                """.formatted(exportedAt, jobId)))
                .andReturn();
    }
}
