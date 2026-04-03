package com.appbackoffice.api.mobile;

import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.job.dto.AssignJobRequest;
import com.appbackoffice.api.job.dto.CreateCaseRequest;
import com.appbackoffice.api.job.dto.CreateCaseResponse;
import com.appbackoffice.api.job.entity.JobStatus;
import com.appbackoffice.api.job.repository.AssignmentRepository;
import com.appbackoffice.api.job.repository.CaseRepository;
import com.appbackoffice.api.job.repository.JobRepository;
import com.appbackoffice.api.job.repository.JobTimelineRepository;
import com.appbackoffice.api.job.service.CaseService;
import com.appbackoffice.api.job.service.JobService;
import com.appbackoffice.api.mobile.repository.InspectionRepository;
import com.appbackoffice.api.mobile.repository.InspectionSubmissionRepository;
import com.appbackoffice.api.user.entity.User;
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

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class InspectionSubmissionIntegrationTest {

    private static final String TENANT_ID = "tenant-mobile-it";
    private static final String CORRELATION_ID = "corr-mobile-it-001";

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
    @Autowired private CaseService caseService;
    @Autowired private JobService jobService;

    private Long operatorUserId;
    private Long jobId;

    @BeforeEach
    void setUp() {
        inspectionRepository.deleteAll();
        inspectionSubmissionRepository.deleteAll();
        jobTimelineRepository.deleteAll();
        assignmentRepository.deleteAll();
        jobRepository.deleteAll();
        caseRepository.deleteAll();
        userRepository.deleteAll();
        tenantRepository.deleteAll();

        tenantRepository.save(new Tenant(TENANT_ID, TENANT_ID, "Tenant Mobile", TenantStatus.ACTIVE));
        User operator = userRepository.save(new User(TENANT_ID, "mobile@tenant.com", "Operador Mobile", "PJ"));
        operatorUserId = operator.getId();

        CreateCaseResponse created = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-MOBILE-001", "Rua Mobile, 123", "RESIDENTIAL", null, "Job Mobile"
        ));
        jobId = created.jobId();
        jobService.assignJob(TENANT_ID, jobId, new AssignJobRequest(operatorUserId), "admin-1");
        jobService.acceptJob(TENANT_ID, jobId, String.valueOf(operatorUserId));
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
        tenantRepository.deleteAll();
    }

    @Test
    void shouldPersistInspectionSubmissionAndAdvanceJobToSubmitted() throws Exception {
        String payload = payloadFor(jobId);

        var result = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", "idem-001")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(202);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("protocolId").asText()).startsWith("INS-");
        assertThat(body.get("status").asText()).isEqualTo("SUBMITTED");
        assertThat(body.get("duplicate").asBoolean()).isFalse();

        assertThat(inspectionRepository.count()).isEqualTo(1);
        assertThat(inspectionSubmissionRepository.count()).isEqualTo(1);
        assertThat(jobRepository.findById(jobId)).isPresent();
        assertThat(jobRepository.findById(jobId).orElseThrow().getStatus()).isEqualTo(JobStatus.SUBMITTED);
        assertThat(jobTimelineRepository.findByJobIdOrderByOccurredAtAsc(jobId)).hasSize(5);
    }

    @Test
    void shouldBeIdempotentOnRepeatedSubmission() throws Exception {
        String payload = payloadFor(jobId);

        var first = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", "idem-002")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        var second = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", "idem-002")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        JsonNode firstBody = objectMapper.readTree(first.getResponse().getContentAsString());
        JsonNode secondBody = objectMapper.readTree(second.getResponse().getContentAsString());

        assertThat(first.getResponse().getStatus()).isEqualTo(202);
        assertThat(second.getResponse().getStatus()).isEqualTo(202);
        assertThat(secondBody.get("duplicate").asBoolean()).isTrue();
        assertThat(secondBody.get("protocolId").asText()).isEqualTo(firstBody.get("protocolId").asText());
        assertThat(secondBody.get("status").asText()).isEqualTo("SUBMITTED");
        assertThat(inspectionRepository.count()).isEqualTo(1);
        assertThat(inspectionSubmissionRepository.count()).isEqualTo(1);
    }

    private String payloadFor(Long jobId) {
        return """
                {
                  "exportedAt": "2026-04-03T12:00:00Z",
                  "job": {"id": "%s", "titulo": "Job Mobile"},
                  "step1": {},
                  "step2": {},
                  "step2Config": {},
                  "review": {"photos": 3}
                }
                """.formatted(jobId);
    }
}