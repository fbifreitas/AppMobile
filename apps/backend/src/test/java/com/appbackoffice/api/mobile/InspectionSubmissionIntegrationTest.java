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
import com.appbackoffice.api.intelligence.repository.FieldEvidenceRecordRepository;
import com.appbackoffice.api.intelligence.repository.InspectionReturnArtifactRepository;
import com.appbackoffice.api.intelligence.repository.OperationalReferenceProfileRepository;
import com.appbackoffice.api.intelligence.port.ResearchProvider;
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
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class InspectionSubmissionIntegrationTest {

    private static final String TENANT_ID = "tenant-mobile-it";
    private static final String CORRELATION_ID = "corr-mobile-it-001";

    private static String freshTimestamp() {
        return Instant.now().toString();
    }

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private InspectionRepository inspectionRepository;
    @Autowired private InspectionSubmissionRepository inspectionSubmissionRepository;
    @Autowired private InspectionReturnArtifactRepository inspectionReturnArtifactRepository;
    @Autowired private FieldEvidenceRecordRepository fieldEvidenceRecordRepository;
    @Autowired private OperationalReferenceProfileRepository operationalReferenceProfileRepository;
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
    @MockBean private ResearchProvider researchProvider;

    private Long operatorUserId;
    private Long alternateOperatorUserId;
    private Long jobId;

    @BeforeEach
    void setUp() {
        inspectionRepository.deleteAll();
        inspectionSubmissionRepository.deleteAll();
        fieldEvidenceRecordRepository.deleteAll();
        operationalReferenceProfileRepository.deleteAll();
        inspectionReturnArtifactRepository.deleteAll();
        jobTimelineRepository.deleteAll();
        assignmentRepository.deleteAll();
        jobRepository.deleteAll();
        caseRepository.deleteAll();
        userRepository.deleteAll();
        tenantApplicationRepository.deleteAll();
        tenantLicenseRepository.deleteAll();
        tenantRepository.deleteAll();

        tenantRepository.save(new Tenant(TENANT_ID, TENANT_ID, "Tenant Mobile", TenantStatus.ACTIVE));
        User operator = userRepository.save(new User(TENANT_ID, "mobile@tenant.com", "Operador Mobile", "PJ"));
        operator.setStatus(UserStatus.APPROVED);
        operator = userRepository.save(operator);
        operatorUserId = operator.getId();
        User alternateOperator = userRepository.save(new User(TENANT_ID, "mobile-alt@tenant.com", "Alternate Operator", "PJ"));
        alternateOperator.setStatus(UserStatus.APPROVED);
        alternateOperator = userRepository.save(alternateOperator);
        alternateOperatorUserId = alternateOperator.getId();

        CreateCaseResponse created = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-MOBILE-001", "Av. Alvaro Ramos, 760, Quarta Parada, Sao Paulo SP", "RESIDENTIAL", null, "Job Mobile"
        ));
        jobId = created.jobId();
        jobService.assignJob(TENANT_ID, jobId, new AssignJobRequest(operatorUserId), "admin-1");
        jobService.acceptJob(TENANT_ID, jobId, String.valueOf(operatorUserId));
    }

    @AfterEach
    void tearDown() {
        inspectionRepository.deleteAll();
        inspectionSubmissionRepository.deleteAll();
        fieldEvidenceRecordRepository.deleteAll();
        operationalReferenceProfileRepository.deleteAll();
        inspectionReturnArtifactRepository.deleteAll();
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
    void shouldPersistInspectionSubmissionAndAdvanceJobToSubmitted() throws Exception {
        String payload = payloadFor(jobId);

        var result = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", "idem-001")
                        .header("X-Request-Timestamp", freshTimestamp())
                        .header("X-Request-Nonce", "nonce-001")
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(202);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("protocolId").asText()).startsWith("INS-");
        assertThat(body.get("processId").asText()).isNotBlank();
        assertThat(body.get("processNumber").asText()).isEqualTo(body.get("protocolId").asText());
        assertThat(body.get("jobId").asLong()).isEqualTo(jobId);
        assertThat(body.get("receivedAt").asText()).isNotBlank();
        assertThat(body.get("status").asText()).isEqualTo("SUBMITTED");
        assertThat(body.get("duplicate").asBoolean()).isFalse();

        assertThat(inspectionRepository.count()).isEqualTo(1);
        assertThat(inspectionSubmissionRepository.count()).isEqualTo(1);
        assertThat(inspectionReturnArtifactRepository.count()).isEqualTo(1);
        assertThat(fieldEvidenceRecordRepository.count()).isGreaterThanOrEqualTo(1);
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
                        .header("X-Request-Timestamp", freshTimestamp())
                        .header("X-Request-Nonce", "nonce-002")
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        var second = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", "idem-002")
                        .header("X-Request-Timestamp", freshTimestamp())
                        .header("X-Request-Nonce", "nonce-003")
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        JsonNode firstBody = objectMapper.readTree(first.getResponse().getContentAsString());
        JsonNode secondBody = objectMapper.readTree(second.getResponse().getContentAsString());

        assertThat(first.getResponse().getStatus()).isEqualTo(202);
        assertThat(second.getResponse().getStatus()).isEqualTo(202);
        assertThat(secondBody.get("duplicate").asBoolean()).isTrue();
        assertThat(secondBody.get("protocolId").asText()).isEqualTo(firstBody.get("protocolId").asText());
        assertThat(secondBody.get("processId").asText()).isEqualTo(firstBody.get("processId").asText());
        assertThat(secondBody.get("processNumber").asText()).isEqualTo(firstBody.get("processNumber").asText());
        assertThat(secondBody.get("jobId").asLong()).isEqualTo(firstBody.get("jobId").asLong());
        assertThat(secondBody.get("status").asText()).isEqualTo("SUBMITTED");
        assertThat(inspectionRepository.count()).isEqualTo(1);
        assertThat(inspectionSubmissionRepository.count()).isEqualTo(1);
        assertThat(inspectionReturnArtifactRepository.count()).isEqualTo(1);
        assertThat(fieldEvidenceRecordRepository.count()).isGreaterThanOrEqualTo(1);
    }

    @Test
    void shouldRejectReusedIdempotencyKeyWhenPayloadChanges() throws Exception {
        String firstPayload = payloadFor(jobId);
        String secondPayload = """
                {
                  "exportedAt": "2026-04-03T12:05:00Z",
                  "job": {"id": "%s", "titulo": "Job Mobile Updated"},
                  "step1": {},
                  "step2": {},
                  "step2Config": {},
                  "review": {"photos": 5}
                }
                """.formatted(jobId);

        var first = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", "idem-003")
                        .header("X-Request-Timestamp", freshTimestamp())
                        .header("X-Request-Nonce", "nonce-004")
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content(firstPayload))
                .andReturn();

        var second = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", "idem-003")
                        .header("X-Request-Timestamp", freshTimestamp())
                        .header("X-Request-Nonce", "nonce-005")
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content(secondPayload))
                .andReturn();

        assertThat(first.getResponse().getStatus()).isEqualTo(202);
        assertThat(second.getResponse().getStatus()).isEqualTo(409);

        JsonNode body = objectMapper.readTree(second.getResponse().getContentAsString());
        assertThat(body.get("code").asText()).isEqualTo("IDEMPOTENCY_KEY_PAYLOAD_MISMATCH");
        assertThat(body.get("message").asText()).contains("Idempotency key");
        assertThat(body.get("details").asText()).isEqualTo("idempotencyKey=idem-003");
        assertThat(inspectionRepository.count()).isEqualTo(1);
        assertThat(inspectionSubmissionRepository.count()).isEqualTo(1);
        assertThat(inspectionReturnArtifactRepository.count()).isEqualTo(1);
    }

    @Test
    void shouldRejectReplayWhenNonceIsReusedInsideProtectionWindow() throws Exception {
        String payload = payloadFor(jobId);

        var first = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", "idem-004")
                        .header("X-Request-Timestamp", Instant.now().toString())
                        .header("X-Request-Nonce", "nonce-replay-001")
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        var second = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", "idem-005")
                        .header("X-Request-Timestamp", Instant.now().toString())
                        .header("X-Request-Nonce", "nonce-replay-001")
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        assertThat(first.getResponse().getStatus()).isEqualTo(202);
        assertThat(second.getResponse().getStatus()).isEqualTo(409);

        JsonNode body = objectMapper.readTree(second.getResponse().getContentAsString());
        assertThat(body.get("code").asText()).isEqualTo("REQUEST_REPLAY_DETECTED");
        assertThat(body.get("details").asText()).isEqualTo("header: X-Request-Nonce");
        assertThat(inspectionRepository.count()).isEqualTo(1);
        assertThat(inspectionSubmissionRepository.count()).isEqualTo(1);
        assertThat(inspectionReturnArtifactRepository.count()).isEqualTo(1);
    }

    @Test
    void shouldRejectInspectionSubmissionFromNonAssignedOperator() throws Exception {
        String payload = payloadFor(jobId);

        var result = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(alternateOperatorUserId))
                        .header("X-Idempotency-Key", "idem-006")
                        .header("X-Request-Timestamp", freshTimestamp())
                        .header("X-Request-Nonce", "nonce-006")
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(403);

        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("code").asText()).isEqualTo("JOB_ACCEPT_FORBIDDEN");
        assertThat(body.get("message").asText()).isEqualTo("Only the assigned field operator can accept this job");
        assertThat(inspectionRepository.count()).isZero();
        assertThat(inspectionSubmissionRepository.count()).isZero();
        assertThat(jobRepository.findById(jobId)).isPresent();
        assertThat(jobRepository.findById(jobId).orElseThrow().getStatus()).isEqualTo(JobStatus.ACCEPTED);
    }

    @Test
    void shouldRejectInspectionSubmissionWhenAssignedOperatorLosesApproval() throws Exception {
        User operator = userRepository.findById(operatorUserId).orElseThrow();
        operator.setStatus(UserStatus.AWAITING_APPROVAL);
        userRepository.save(operator);

        String payload = payloadFor(jobId);

        var result = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", "idem-007")
                        .header("X-Request-Timestamp", freshTimestamp())
                        .header("X-Request-Nonce", "nonce-007")
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(403);

        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("code").asText()).isEqualTo("JOB_ACTOR_NOT_APPROVED");
        assertThat(body.get("message").asText()).isEqualTo("Assigned actor is not approved for field work");
        assertThat(inspectionRepository.count()).isZero();
        assertThat(inspectionSubmissionRepository.count()).isZero();
        assertThat(jobRepository.findById(jobId)).isPresent();
        assertThat(jobRepository.findById(jobId).orElseThrow().getStatus()).isEqualTo(JobStatus.ACCEPTED);
    }

    @Test
    void shouldIngestOperationalReferenceFeedbackFromSubmittedInspection() throws Exception {
        String payload = """
                {
                  "exportedAt": "2026-04-17T12:00:00Z",
                  "job": {"id": "%s", "titulo": "Job Mobile"},
                  "step1": {
                    "assetType": "Urbano",
                    "assetSubtype": "Apartamento",
                    "refinedAssetSubtype": "Apartamento padrao",
                    "propertyStandard": "Padrao",
                    "candidateAssetSubtypes": ["Apartamento", "Apartamento padrao", "Duplex"]
                  },
                  "step2": {},
                  "step2Config": {},
                  "review": {
                    "reviewedCaptures": [
                      {
                        "subjectContext": "Area interna",
                        "targetItem": "Cozinha 2",
                        "targetItemBase": "Cozinha",
                        "targetQualifier": "Janela",
                        "materialAttribute": "Aluminio",
                        "conditionState": "Bom"
                      },
                      {
                        "subjectContext": "Area interna",
                        "targetItem": "Sala de estar",
                        "targetItemBase": "Sala de estar",
                        "targetQualifier": "Porta",
                        "materialAttribute": "Madeira",
                        "conditionState": "Regular"
                      }
                    ]
                  }
                }
                """.formatted(jobId);

        var result = mockMvc.perform(post("/api/mobile/inspections/finalized")
                        .header("X-Tenant-Id", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", String.valueOf(operatorUserId))
                        .header("X-Idempotency-Key", "idem-feedback-001")
                        .header("X-Request-Timestamp", freshTimestamp())
                        .header("X-Request-Nonce", "nonce-feedback-001")
                        .header("X-Api-Version", "v1")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(202);
        assertThat(operationalReferenceProfileRepository.findAllByOrderByPriorityWeightDescIdAsc())
                .anyMatch(item -> item.getScopeType().name().equals("HISTORICAL_REFERENCE")
                        && TENANT_ID.equals(item.getTenantId())
                        && "Apartamento".equals(item.getAssetSubtype())
                        && item.getFeedbackCount() >= 1
                        && item.getPhotoLocationsJson().contains("Cozinha"));
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
