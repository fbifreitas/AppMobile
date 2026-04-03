package com.appbackoffice.api.integration;

import com.appbackoffice.api.auth.repository.IdentityBindingRepository;
import com.appbackoffice.api.auth.repository.SessionRepository;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.job.repository.AssignmentRepository;
import com.appbackoffice.api.job.repository.CaseRepository;
import com.appbackoffice.api.job.repository.JobRepository;
import com.appbackoffice.api.job.repository.JobTimelineRepository;
import com.appbackoffice.api.integration.repository.IntegrationDemandRepository;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.user.repository.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class IntegrationDemandIntegrationTest {

    private static final String TENANT_ID = "tenant-integration-it";
    private static final String CORRELATION_ID = "corr-integration-it-001";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private IntegrationDemandRepository integrationDemandRepository;

        @Autowired
        private JobTimelineRepository jobTimelineRepository;

        @Autowired
        private AssignmentRepository assignmentRepository;

        @Autowired
        private JobRepository jobRepository;

        @Autowired
        private CaseRepository caseRepository;

        @Autowired
        private SessionRepository sessionRepository;

        @Autowired
        private IdentityBindingRepository identityBindingRepository;

        @Autowired
        private UserCredentialRepository userCredentialRepository;

        @Autowired
        private MembershipRepository membershipRepository;

        @Autowired
        private UserRepository userRepository;

    @Autowired
    private TenantRepository tenantRepository;

    @BeforeEach
    void setUp() {
                integrationDemandRepository.deleteAll();
                jobTimelineRepository.deleteAll();
                assignmentRepository.deleteAll();
                jobRepository.deleteAll();
                caseRepository.deleteAll();
                sessionRepository.deleteAll();
                identityBindingRepository.deleteAll();
                userCredentialRepository.deleteAll();
                membershipRepository.deleteAll();
                userRepository.deleteAll();
        tenantRepository.deleteAll();
        tenantRepository.save(new Tenant(TENANT_ID, TENANT_ID, "Tenant Integration", TenantStatus.ACTIVE));
    }

    @Test
    void shouldCreateAndQueryDemand() throws Exception {
        String payload = """
                {
                  "externalId": "FIN-12345",
                  "tenantId": "tenant-integration-it",
                  "requestedBy": "financeira-alpha",
                  "inspectionType": "RESIDENTIAL",
                  "requestedDeadline": "2026-05-01T00:00:00Z",
                  "propertyAddress": {
                    "street": "Rua A",
                    "city": "Sao Paulo",
                    "state": "SP",
                    "zipCode": "01000-000"
                  },
                  "clientData": {
                    "masked": true
                  }
                }
                """;

        var createResult = mockMvc.perform(post("/api/integration/demands")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "TENANT_ADMIN")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        assertThat(createResult.getResponse().getStatus()).isEqualTo(201);
        JsonNode createBody = objectMapper.readTree(createResult.getResponse().getContentAsString());
        assertThat(createBody.get("externalId").asText()).isEqualTo("FIN-12345");
        assertThat(createBody.get("status").asText()).isEqualTo("CASE_CREATED");
        assertThat(createBody.get("caseId").asLong()).isPositive();
        assertThat(createBody.get("jobId").asLong()).isPositive();
        assertThat(createBody.get("created").asBoolean()).isTrue();

        var getResult = mockMvc.perform(get("/api/integration/demands/FIN-12345")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "AUDITOR")
                        .queryParam("tenantId", TENANT_ID))
                .andReturn();

        assertThat(getResult.getResponse().getStatus()).isEqualTo(200);
        JsonNode getBody = objectMapper.readTree(getResult.getResponse().getContentAsString());
        assertThat(getBody.get("externalId").asText()).isEqualTo("FIN-12345");
        assertThat(getBody.get("caseId").asLong()).isEqualTo(createBody.get("caseId").asLong());
        assertThat(getBody.get("jobId").asLong()).isEqualTo(createBody.get("jobId").asLong());
    }

    @Test
    void shouldBeIdempotentOnDuplicateExternalId() throws Exception {
        String payload = """
                {
                  "externalId": "FIN-888",
                  "tenantId": "tenant-integration-it",
                  "requestedBy": "financeira-alpha",
                  "inspectionType": "COMMERCIAL",
                  "requestedDeadline": "2026-05-01T00:00:00Z",
                  "propertyAddress": {
                    "street": "Rua B",
                    "city": "Campinas",
                    "state": "SP",
                    "zipCode": "13000-000"
                  }
                }
                """;

        var first = mockMvc.perform(post("/api/integration/demands")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "TENANT_ADMIN")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        var second = mockMvc.perform(post("/api/integration/demands")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "TENANT_ADMIN")
                        .contentType("application/json")
                        .content(payload))
                .andReturn();

        assertThat(first.getResponse().getStatus()).isEqualTo(201);
        assertThat(second.getResponse().getStatus()).isEqualTo(200);

        JsonNode firstBody = objectMapper.readTree(first.getResponse().getContentAsString());
        JsonNode secondBody = objectMapper.readTree(second.getResponse().getContentAsString());
        assertThat(secondBody.get("created").asBoolean()).isFalse();
        assertThat(secondBody.get("caseId").asLong()).isEqualTo(firstBody.get("caseId").asLong());
        assertThat(secondBody.get("jobId").asLong()).isEqualTo(firstBody.get("jobId").asLong());
    }

    @Test
    void shouldRejectInvalidPayload() throws Exception {
        String invalidPayload = """
                {
                  "externalId": "FIN-INVALID",
                  "requestedBy": "financeira-alpha",
                  "inspectionType": "LAND",
                  "requestedDeadline": "2026-05-01T00:00:00Z",
                  "propertyAddress": {
                    "street": "Rua C",
                    "city": "Santos",
                    "state": "SP",
                    "zipCode": "11000-000"
                  }
                }
                """;

        var result = mockMvc.perform(post("/api/integration/demands")
                        .header("X-Correlation-Id", CORRELATION_ID)
                        .header("X-Actor-Role", "TENANT_ADMIN")
                        .contentType("application/json")
                        .content(invalidPayload))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(400);
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(body.get("code").asText()).isEqualTo("REQ_VALIDATION_FAILED");
    }
}
