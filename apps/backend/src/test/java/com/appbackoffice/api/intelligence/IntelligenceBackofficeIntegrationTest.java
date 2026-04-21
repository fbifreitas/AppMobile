package com.appbackoffice.api.intelligence;

import com.appbackoffice.api.auth.repository.IdentityBindingRepository;
import com.appbackoffice.api.auth.repository.SessionRepository;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.intelligence.entity.CaseEnrichmentRunEntity;
import com.appbackoffice.api.intelligence.entity.FieldEvidenceRecordEntity;
import com.appbackoffice.api.intelligence.entity.FieldEvidenceStatus;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanSnapshotEntity;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanStatus;
import com.appbackoffice.api.intelligence.entity.InspectionReturnArtifactEntity;
import com.appbackoffice.api.intelligence.port.ResearchFact;
import com.appbackoffice.api.intelligence.port.ResearchProvider;
import com.appbackoffice.api.intelligence.port.ResearchProviderRequest;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.appbackoffice.api.intelligence.repository.CaseEnrichmentRunRepository;
import com.appbackoffice.api.intelligence.repository.ExecutionPlanSnapshotRepository;
import com.appbackoffice.api.intelligence.repository.FieldEvidenceRecordRepository;
import com.appbackoffice.api.intelligence.repository.InspectionReturnArtifactRepository;
import com.appbackoffice.api.job.entity.InspectionCase;
import com.appbackoffice.api.job.entity.Job;
import com.appbackoffice.api.job.repository.CaseRepository;
import com.appbackoffice.api.job.repository.JobRepository;
import com.appbackoffice.api.mobile.entity.InspectionEntity;
import com.appbackoffice.api.mobile.entity.InspectionSubmissionEntity;
import com.appbackoffice.api.mobile.repository.InspectionRepository;
import com.appbackoffice.api.mobile.repository.InspectionSubmissionRepository;
import com.appbackoffice.api.user.repository.UserLifecycleRepository;
import com.appbackoffice.api.user.repository.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentMatchers;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class IntelligenceBackofficeIntegrationTest {

    private static final String TENANT_ID = "tenant-intelligence";
    private static final String CORRELATION_ID = "corr-intelligence-001";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TenantRepository tenantRepository;

    @Autowired
    private MembershipRepository membershipRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserLifecycleRepository userLifecycleRepository;

    @Autowired
    private UserCredentialRepository userCredentialRepository;

    @Autowired
    private IdentityBindingRepository identityBindingRepository;

    @Autowired
    private SessionRepository sessionRepository;

    @Autowired
    private CaseRepository caseRepository;

    @Autowired
    private JobRepository jobRepository;

    @Autowired
    private CaseEnrichmentRunRepository runRepository;

    @Autowired
    private ExecutionPlanSnapshotRepository snapshotRepository;

    @Autowired
    private InspectionReturnArtifactRepository inspectionReturnArtifactRepository;

    @Autowired
    private FieldEvidenceRecordRepository fieldEvidenceRecordRepository;

    @Autowired
    private InspectionRepository inspectionRepository;

    @Autowired
    private InspectionSubmissionRepository inspectionSubmissionRepository;

    @MockBean
    private ResearchProvider researchProvider;

    @BeforeEach
    void setUp() {
        fieldEvidenceRecordRepository.deleteAll();
        inspectionReturnArtifactRepository.deleteAll();
        inspectionRepository.deleteAll();
        inspectionSubmissionRepository.deleteAll();
        snapshotRepository.deleteAll();
        runRepository.deleteAll();
        jobRepository.deleteAll();
        caseRepository.deleteAll();
        sessionRepository.deleteAll();
        identityBindingRepository.deleteAll();
        userCredentialRepository.deleteAll();
        membershipRepository.deleteAll();
        userLifecycleRepository.deleteAll();
        userRepository.deleteAll();
        tenantRepository.deleteAll();
        tenantRepository.save(new Tenant(TENANT_ID, TENANT_ID, "Tenant Intelligence", TenantStatus.ACTIVE));
    }

    @Test
    void shouldTriggerEnrichmentAndExposeLatestExecutionPlanForBackofficeAndMobile() throws Exception {
        InspectionCase inspectionCase = caseRepository.save(new InspectionCase(
                TENANT_ID,
                "CASE-1001",
                "Av. Paulista, 1000",
                -23.5614,
                -46.6559,
                "RESIDENTIAL",
                Instant.now().plusSeconds(86400)
        ));
        Job job = jobRepository.save(new Job(
                inspectionCase.getId(),
                TENANT_ID,
                "Inspection job",
                Instant.now().plusSeconds(86400)
        ));

        JsonNode rawPayload = objectMapper.createObjectNode()
                .put("providerName", "AI_GATEWAY")
                .put("model", "inspection-research-v1")
                .put("promptVersion", "v1")
                .put("confidenceScore", 0.91)
                .put("requiresManualReview", false);

        given(researchProvider.execute(ArgumentMatchers.any(ResearchProviderRequest.class)))
                .willReturn(new ResearchProviderResponse(
                        "AI_GATEWAY",
                        "inspection-research-v1",
                        "v1",
                        List.of(
                                new ResearchFact("property_taxonomy", "RESIDENTIAL_VERTICAL", 0.94, "AI_GATEWAY", "Detected from contextual features"),
                                new ResearchFact("property_subtype", "Apartamento", 0.93, "AI_GATEWAY", "Detected from listing context"),
                                new ResearchFact("private_area_m2", "300", 0.92, "AI_GATEWAY", "Area extracted from structured source"),
                                new ResearchFact("candidate_asset_subtypes", "Apartamento;Duplex", 0.72, "AI_GATEWAY", "Subtype ambiguity preserved for field validation"),
                                new ResearchFact("initial_context", "External area", 0.88, "AI_GATEWAY", "Facade-first recommendation")
                        ),
                        List.of("https://example.org/research/case-1001"),
                        rawPayload,
                        JsonNodeFactory.instance.objectNode()
                                .put("confidenceScore", 0.91)
                                .put("requiresManualReview", false),
                        0.91,
                        false,
                        List.of("RESEARCH_CONFIRMED")
                ));

        MvcResult triggerResult = mockMvc.perform(post("/api/backoffice/intelligence/cases/{caseId}/enrichment/trigger", inspectionCase.getId())
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", "operator-web")
                        .header("X-Actor-Role", "COORDINATOR")
                        .contentType(MediaType.APPLICATION_JSON))
                .andReturn();

        assertThat(triggerResult.getResponse().getStatus()).isEqualTo(202);
        JsonNode triggerBody = objectMapper.readTree(triggerResult.getResponse().getContentAsString());
        assertThat(triggerBody.get("status").asText()).isEqualTo("COMPLETED");
        assertThat(triggerBody.at("/executionPlan/status").asText()).isEqualTo("PUBLISHED");
        assertThat(triggerBody.at("/executionPlan/plan/cameraConfig/mode").asText()).isEqualTo("guided");

        CaseEnrichmentRunEntity runEntity = runRepository.findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(TENANT_ID, inspectionCase.getId()).orElseThrow();
        assertThat(runEntity.getRequestStorageKey()).isNotBlank();
        assertThat(runEntity.getResponseRawStorageKey()).isNotBlank();
        assertThat(runEntity.getResponseNormalizedStorageKey()).isNotBlank();

        ExecutionPlanSnapshotEntity snapshotEntity = snapshotRepository.findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(TENANT_ID, inspectionCase.getId()).orElseThrow();
        assertThat(snapshotEntity.getPlanJson()).contains("RESIDENTIAL_VERTICAL");

        MvcResult latestRunResult = mockMvc.perform(get("/api/backoffice/intelligence/cases/{caseId}/enrichment-runs/latest", inspectionCase.getId())
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(latestRunResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode latestRunBody = objectMapper.readTree(latestRunResult.getResponse().getContentAsString());
        assertThat(latestRunBody.get("providerName").asText()).isEqualTo("AI_GATEWAY");
        assertThat(latestRunBody.get("requestStorageKey").asText()).isNotBlank();

        MvcResult latestPlanResult = mockMvc.perform(get("/api/backoffice/intelligence/cases/{caseId}/execution-plan/latest", inspectionCase.getId())
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(latestPlanResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode latestPlanBody = objectMapper.readTree(latestPlanResult.getResponse().getContentAsString());
        assertThat(latestPlanBody.at("/plan/propertyProfile/taxonomy").asText()).isEqualTo("RESIDENTIAL_VERTICAL");
        assertThat(latestPlanBody.at("/plan/propertyProfile/canonicalAssetType").asText()).isEqualTo("Urbano");
        assertThat(latestPlanBody.at("/plan/propertyProfile/canonicalAssetSubtype").asText()).isEqualTo("Apartamento");
        assertThat(latestPlanBody.at("/plan/propertyProfile/candidateAssetSubtypes/0").asText()).isEqualTo("Apartamento");
        assertThat(latestPlanBody.at("/plan/propertyProfile/candidateAssetSubtypes/1").asText()).isEqualTo("Duplex");
        assertThat(latestPlanBody.at("/plan/propertyProfile/latitude").asDouble()).isEqualTo(-23.5614);
        assertThat(latestPlanBody.at("/plan/propertyProfile/longitude").asDouble()).isEqualTo(-46.6559);
        assertThat(latestPlanBody.at("/plan/step1Config/candidateAssetSubtypes/1").asText()).isEqualTo("Duplex");
        assertThat(latestPlanBody.at("/plan/cameraConfig/suggestedPhotoLocations/0").asText()).isEqualTo("Fachada");
        assertThat(latestPlanBody.at("/plan/cameraConfig/compositionProfiles/0/photoLocation").asText()).isEqualTo("Fachada");
        assertThat(latestPlanBody.at("/plan/cameraConfig/compositionProfiles/2/photoLocation").asText()).isEqualTo("Cozinha");
        assertThat(latestPlanBody.at("/plan/traceability/sourceRunId").asLong()).isEqualTo(runEntity.getId());

        assertThat(snapshotEntity.getPlanJson()).contains("\"assetSubtype\":\"Apartamento\"");
    }

    @Test
    void shouldExposeManualResolutionQueueAndReportBasis() throws Exception {
        InspectionCase inspectionCase = caseRepository.save(new InspectionCase(
                TENANT_ID,
                "CASE-2001",
                "Rua Inteligente, 10",
                -23.5614,
                -46.6559,
                "RESIDENTIAL",
                Instant.now().plusSeconds(86400)
        ));
        Job job = jobRepository.save(new Job(
                inspectionCase.getId(),
                TENANT_ID,
                "Inspection job review",
                Instant.now().plusSeconds(86400)
        ));

        JsonNode rawPayload = objectMapper.createObjectNode()
                .put("providerName", "AI_GATEWAY")
                .put("model", "inspection-research-v1")
                .put("promptVersion", "v2")
                .put("confidenceScore", 0.54)
                .put("requiresManualReview", true);

        given(researchProvider.execute(ArgumentMatchers.any(ResearchProviderRequest.class)))
                .willReturn(new ResearchProviderResponse(
                        "AI_GATEWAY",
                        "inspection-research-v1",
                        "v2",
                        List.of(new ResearchFact("property_taxonomy", "RESIDENTIAL_VERTICAL", 0.54, "AI_GATEWAY", "Low confidence")),
                        List.of("https://example.org/research/case-2001"),
                        rawPayload,
                        JsonNodeFactory.instance.objectNode()
                                .put("confidenceScore", 0.54)
                                .put("requiresManualReview", true),
                        0.54,
                        true,
                        List.of("REVIEW_REQUIRED")
                ));

        mockMvc.perform(post("/api/backoffice/intelligence/cases/{caseId}/enrichment/trigger", inspectionCase.getId())
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Id", "operator-web")
                        .header("X-Actor-Role", "COORDINATOR")
                        .contentType(MediaType.APPLICATION_JSON))
                .andReturn();

        ExecutionPlanSnapshotEntity snapshotEntity = snapshotRepository
                .findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(TENANT_ID, inspectionCase.getId())
                .orElseThrow();

        InspectionSubmissionEntity submission = new InspectionSubmissionEntity();
        submission.setJobId(job.getId());
        submission.setTenantId(TENANT_ID);
        submission.setFieldAgentId(42L);
        submission.setIdempotencyKey("idem-intelligence-7001");
        submission.setProtocolId("protocol-intelligence-7001");
        submission.setStatus("SUBMITTED");
        submission.setPayloadJson("{\"reviewPhotoCount\":2}");
        submission = inspectionSubmissionRepository.save(submission);

        InspectionEntity inspection = new InspectionEntity();
        inspection.setSubmissionId(submission.getId());
        inspection.setJobId(job.getId());
        inspection.setTenantId(TENANT_ID);
        inspection.setFieldAgentId(42L);
        inspection.setIdempotencyKey("idem-intelligence-7001");
        inspection.setProtocolId("protocol-intelligence-7001");
        inspection.setStatus("SUBMITTED");
        inspection.setPayloadJson("{\"reviewPhotoCount\":2}");
        inspection = inspectionRepository.save(inspection);

        InspectionReturnArtifactEntity returnArtifact = new InspectionReturnArtifactEntity();
        returnArtifact.setInspectionId(inspection.getId());
        returnArtifact.setSubmissionId(submission.getId());
        returnArtifact.setTenantId(TENANT_ID);
        returnArtifact.setCaseId(inspectionCase.getId());
        returnArtifact.setJobId(job.getId());
        returnArtifact.setExecutionPlanSnapshotId(snapshotEntity.getId());
        returnArtifact.setRawStorageKey("raw/cases/%s/inspection-return.json".formatted(inspectionCase.getId()));
        returnArtifact.setNormalizedStorageKey("normalized/cases/%s/inspection-return.json".formatted(inspectionCase.getId()));
        returnArtifact.setSummaryJson("""
                {"reviewPhotoCount":2,"manualReviewRequired":true}
                """);
        inspectionReturnArtifactRepository.save(returnArtifact);

        FieldEvidenceRecordEntity fieldEvidence = new FieldEvidenceRecordEntity();
        fieldEvidence.setInspectionId(inspection.getId());
        fieldEvidence.setTenantId(TENANT_ID);
        fieldEvidence.setCaseId(inspectionCase.getId());
        fieldEvidence.setJobId(job.getId());
        fieldEvidence.setSourceSection("review");
        fieldEvidence.setMacroLocation("Rua");
        fieldEvidence.setEnvironmentName("Fachada");
        fieldEvidence.setElementName("Porta principal");
        fieldEvidence.setRequiredFlag(true);
        fieldEvidence.setMinPhotos(2);
        fieldEvidence.setCapturedPhotos(1);
        fieldEvidence.setEvidenceStatus(FieldEvidenceStatus.REVIEW_REQUIRED);
        fieldEvidence.setEvidenceJson("""
                {"label":"Porta principal","photos":1}
                """);
        fieldEvidenceRecordRepository.save(fieldEvidence);

        MvcResult queueResult = mockMvc.perform(get("/api/backoffice/intelligence/manual-resolution-queue")
                        .queryParam("tenantId", TENANT_ID)
                        .queryParam("limit", "10")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(queueResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode queueBody = objectMapper.readTree(queueResult.getResponse().getContentAsString());
        assertThat(queueBody.get("total").asInt()).isEqualTo(1);
        assertThat(queueBody.at("/items/0/caseId").asLong()).isEqualTo(inspectionCase.getId());
        assertThat(queueBody.at("/items/0/latestRunStatus").asText()).isEqualTo("REVIEW_REQUIRED");
        assertThat(queueBody.at("/items/0/executionPlanStatus").asText()).isEqualTo("REVIEW_REQUIRED");
        assertThat(queueBody.at("/items/0/pendingReasons/0").asText()).isEqualTo("ENRICHMENT_REVIEW_REQUIRED");

        MvcResult reportBasisResult = mockMvc.perform(get("/api/backoffice/intelligence/cases/{caseId}/report-basis", inspectionCase.getId())
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(reportBasisResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode reportBasisBody = objectMapper.readTree(reportBasisResult.getResponse().getContentAsString());
        assertThat(reportBasisBody.get("caseId").asLong()).isEqualTo(inspectionCase.getId());
        assertThat(reportBasisBody.at("/latestRun/status").asText()).isEqualTo("REVIEW_REQUIRED");
        assertThat(reportBasisBody.at("/latestExecutionPlan/status").asText()).isEqualTo("REVIEW_REQUIRED");
        assertThat(reportBasisBody.at("/latestReturnArtifact/summary/manualReviewRequired").asBoolean()).isTrue();
        assertThat(reportBasisBody.at("/fieldEvidence/0/status").asText()).isEqualTo("REVIEW_REQUIRED");
        assertThat(reportBasisBody.at("/latestExecutionPlan/plan/traceability/sourceRunId").asLong()).isPositive();
        assertThat(reportBasisBody.at("/latestExecutionPlan/plan/cameraConfig/capturePlan/0/required").asBoolean()).isTrue();

        MvcResult analyticsResult = mockMvc.perform(get("/api/backoffice/intelligence/analytics-readiness")
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(analyticsResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode analyticsBody = objectMapper.readTree(analyticsResult.getResponse().getContentAsString());
        assertThat(analyticsBody.get("enrichmentRuns").asLong()).isGreaterThanOrEqualTo(1);
        assertThat(analyticsBody.get("reviewRequiredRuns").asLong()).isEqualTo(1);
        assertThat(analyticsBody.get("reviewRequiredExecutionPlans").asLong()).isEqualTo(1);
        assertThat(analyticsBody.get("inspectionReturnArtifacts").asLong()).isEqualTo(1);
        assertThat(analyticsBody.get("fieldEvidenceRecords").asLong()).isGreaterThanOrEqualTo(1);
        assertThat(analyticsBody.get("manualResolutionCases").asLong()).isEqualTo(1);
    }

    @Test
    void shouldExposeAndRebuildOperationalReferenceProfiles() throws Exception {
        InspectionCase inspectionCase = caseRepository.save(new InspectionCase(
                TENANT_ID,
                "CASE-REF-1001",
                "Av. Alvaro Ramos, 760, Quarta Parada, Sao Paulo SP",
                -23.5505,
                -46.6333,
                "RESIDENTIAL",
                Instant.now().plusSeconds(86400)
        ));

        ExecutionPlanSnapshotEntity snapshot = new ExecutionPlanSnapshotEntity();
        snapshot.setTenantId(TENANT_ID);
        snapshot.setCaseId(inspectionCase.getId());
        snapshot.setStatus(ExecutionPlanStatus.PUBLISHED);
        snapshot.setPublishedAt(Instant.now());
        snapshot.setPlanJson("""
                {
                  "propertyProfile": {
                    "address": "Av. Alvaro Ramos, 760, Quarta Parada, Sao Paulo SP",
                    "canonicalAssetType": "Urbano",
                    "canonicalAssetSubtype": "Apartamento",
                    "refinedAssetSubtype": "Apartamento padrao",
                    "propertyStandard": "Padrao",
                    "candidateAssetSubtypes": ["Apartamento", "Apartamento padrao", "Duplex"]
                  },
                  "cameraConfig": {
                    "compositionProfiles": [
                      {
                        "macroLocal": "Rua",
                        "photoLocation": "Fachada",
                        "required": true,
                        "minPhotos": 1,
                        "elements": [
                          {
                            "element": "Porta",
                            "materials": ["Metal"],
                            "states": ["Bom", "Regular"]
                          }
                        ]
                      }
                    ]
                  }
                }
                """);
        snapshotRepository.save(snapshot);

        MvcResult listBeforeResult = mockMvc.perform(get("/api/backoffice/intelligence/reference-profiles")
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(listBeforeResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode listBeforeBody = objectMapper.readTree(listBeforeResult.getResponse().getContentAsString());
        assertThat(listBeforeBody.get("total").asInt()).isGreaterThan(0);

        MvcResult rebuildResult = mockMvc.perform(post("/api/backoffice/intelligence/reference-profiles/rebuild")
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(rebuildResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode rebuildBody = objectMapper.readTree(rebuildResult.getResponse().getContentAsString());
        assertThat(rebuildBody.get("tenantId").asText()).isEqualTo(TENANT_ID);
        assertThat(rebuildBody.get("rebuiltHistoricalProfiles").asInt()).isGreaterThanOrEqualTo(1);
        assertThat(rebuildBody.get("totalProfilesAfterRebuild").asInt()).isGreaterThan(0);

        MvcResult listAfterResult = mockMvc.perform(get("/api/backoffice/intelligence/reference-profiles")
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(listAfterResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode listAfterBody = objectMapper.readTree(listAfterResult.getResponse().getContentAsString());
        assertThat(listAfterBody.get("total").asInt()).isGreaterThan(0);
        assertThat(listAfterBody.get("items").toString()).contains("GLOBAL_REFERENCE");
        assertThat(listAfterBody.get("items").toString()).contains("HISTORICAL_REFERENCE");
    }

    @Test
    void shouldCreateUpdateAndDeactivateTenantReferenceProfile() throws Exception {
        MvcResult createResult = mockMvc.perform(post("/api/backoffice/intelligence/reference-profiles")
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scopeType": "REGIONAL_REFERENCE",
                                  "activeFlag": true,
                                  "assetType": "Urbano",
                                  "assetSubtype": "Casa",
                                  "refinedAssetSubtype": "Casa geminada",
                                  "propertyStandard": "Padrao",
                                  "regionState": "SP",
                                  "regionCity": "Sao Paulo",
                                  "regionDistrict": "Quarta Parada",
                                  "priorityWeight": 160,
                                  "confidenceScore": 0.94,
                                  "candidateSubtypes": ["Casa", "Casa geminada", "Sobrado"],
                                  "photoLocations": ["Fachada", "Sala de estar", "Cozinha"]
                                }
                                """))
                .andReturn();

        assertThat(createResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode createdBody = objectMapper.readTree(createResult.getResponse().getContentAsString());
        Long profileId = createdBody.get("id").asLong();
        assertThat(createdBody.get("editable").asBoolean()).isTrue();
        assertThat(createdBody.get("activeFlag").asBoolean()).isTrue();
        assertThat(createdBody.get("sourceType").asText()).isEqualTo("MANUAL_CURATION");

        MvcResult updateResult = mockMvc.perform(put("/api/backoffice/intelligence/reference-profiles/{profileId}", profileId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scopeType": "REGIONAL_REFERENCE",
                                  "activeFlag": true,
                                  "assetType": "Urbano",
                                  "assetSubtype": "Casa",
                                  "refinedAssetSubtype": "Sobrado",
                                  "propertyStandard": "Superior",
                                  "regionState": "SP",
                                  "regionCity": "Sao Paulo",
                                  "regionDistrict": "Quarta Parada",
                                  "priorityWeight": 175,
                                  "confidenceScore": 0.95,
                                  "candidateSubtypes": ["Casa", "Sobrado"],
                                  "photoLocations": ["Fachada", "Escada interna", "Sala de estar"]
                                }
                                """))
                .andReturn();

        assertThat(updateResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode updatedBody = objectMapper.readTree(updateResult.getResponse().getContentAsString());
        assertThat(updatedBody.get("refinedAssetSubtype").asText()).isEqualTo("Sobrado");
        assertThat(updatedBody.get("priorityWeight").asInt()).isEqualTo(175);

        MvcResult deactivateResult = mockMvc.perform(post("/api/backoffice/intelligence/reference-profiles/{profileId}/deactivate", profileId)
                        .queryParam("tenantId", TENANT_ID)
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "COORDINATOR"))
                .andReturn();

        assertThat(deactivateResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode deactivatedBody = objectMapper.readTree(deactivateResult.getResponse().getContentAsString());
        assertThat(deactivatedBody.get("activeFlag").asBoolean()).isFalse();
    }
}
