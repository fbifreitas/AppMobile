package com.appbackoffice.api.job;

import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.job.dto.AssignJobRequest;
import com.appbackoffice.api.job.dto.CreateCaseRequest;
import com.appbackoffice.api.job.dto.CreateCaseResponse;
import com.appbackoffice.api.job.dto.JobDetailResponse;
import com.appbackoffice.api.job.dto.JobSummaryResponse;
import com.appbackoffice.api.job.dto.JobTimelineResponse;
import com.appbackoffice.api.job.entity.JobStatus;
import com.appbackoffice.api.job.repository.AssignmentRepository;
import com.appbackoffice.api.job.repository.CaseRepository;
import com.appbackoffice.api.job.repository.JobRepository;
import com.appbackoffice.api.job.repository.JobTimelineRepository;
import com.appbackoffice.api.job.service.CaseService;
import com.appbackoffice.api.job.service.JobService;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@ActiveProfiles("test")
class CaseJobDomainIntegrationTest {

    private static final String TENANT_ID = "tenant-job-test";

    @Autowired private CaseService caseService;
    @Autowired private JobService jobService;
    @Autowired private TenantRepository tenantRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private JobTimelineRepository timelineRepository;
    @Autowired private AssignmentRepository assignmentRepository;
    @Autowired private JobRepository jobRepository;
    @Autowired private CaseRepository caseRepository;

    private Long operatorUserId;

    private void cleanAll() {
        timelineRepository.deleteAll();
        assignmentRepository.deleteAll();
        jobRepository.deleteAll();
        caseRepository.deleteAll();
        userRepository.deleteAll();
        tenantRepository.deleteAll();
    }

    @BeforeEach
    void setUp() {
        cleanAll();
        tenantRepository.save(new Tenant(TENANT_ID, "tenant-job-slug", "Tenant Job Test", TenantStatus.ACTIVE));
        User operator = userRepository.save(new User(TENANT_ID, "vistoriador@teste.com", "Vistoriador Teste", "PJ"));
        operatorUserId = operator.getId();
    }

    @AfterEach
    void tearDown() {
        cleanAll();
    }

    @Test
    void shouldCreateCaseAndJobInEligibleForDispatch() {
        CreateCaseRequest request = new CreateCaseRequest(
                "CASE-001", "Rua Teste, 123", "RESIDENTIAL",
                Instant.now().plus(7, ChronoUnit.DAYS), "Vistoria Residencial"
        );

        CreateCaseResponse response = caseService.createCase(TENANT_ID, "admin-1", request);

        assertThat(response.caseId()).isNotNull();
        assertThat(response.caseNumber()).isEqualTo("CASE-001");
        assertThat(response.jobId()).isNotNull();
        assertThat(response.jobStatus()).isEqualTo(JobStatus.ELIGIBLE_FOR_DISPATCH.name());
    }

    @Test
    void shouldTransitionJobToOfferedOnAssign() {
        CreateCaseResponse caseResp = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-002", "Av. Principal, 456", "COMMERCIAL",
                null, "Vistoria Comercial"
        ));
        Long jobId = caseResp.jobId();

        JobSummaryResponse assigned = jobService.assignJob(
                TENANT_ID, jobId, new AssignJobRequest(operatorUserId), "admin-1"
        );

        assertThat(assigned.status()).isEqualTo(JobStatus.OFFERED.name());
        assertThat(assigned.assignedTo()).isEqualTo(operatorUserId);

        assertThat(assignmentRepository.findByJobId(jobId)).hasSize(1);
    }

    @Test
    void shouldTransitionJobToAcceptedOnAccept() {
        CreateCaseResponse caseResp = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-003", "Travessa do Aceite, 10", "RESIDENTIAL",
                null, "Vistoria Aceite"
        ));
        jobService.assignJob(TENANT_ID, caseResp.jobId(), new AssignJobRequest(operatorUserId), "admin-1");

        JobSummaryResponse accepted = jobService.acceptJob(
                TENANT_ID, caseResp.jobId(), String.valueOf(operatorUserId)
        );

        assertThat(accepted.status()).isEqualTo(JobStatus.ACCEPTED.name());
    }

    @Test
    void shouldRecordTimelineEntriesOnEachTransition() {
        CreateCaseResponse caseResp = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-004", "Rua Timeline, 99", "RESIDENTIAL",
                null, "Vistoria Timeline"
        ));
        Long jobId = caseResp.jobId();

        jobService.assignJob(TENANT_ID, jobId, new AssignJobRequest(operatorUserId), "admin-1");
        jobService.acceptJob(TENANT_ID, jobId, String.valueOf(operatorUserId));

        JobTimelineResponse timeline = jobService.getTimeline(TENANT_ID, jobId);

        assertThat(timeline.entries()).hasSize(2);
        assertThat(timeline.entries().get(0).fromStatus()).isEqualTo(JobStatus.ELIGIBLE_FOR_DISPATCH.name());
        assertThat(timeline.entries().get(0).toStatus()).isEqualTo(JobStatus.OFFERED.name());
        assertThat(timeline.entries().get(1).fromStatus()).isEqualTo(JobStatus.OFFERED.name());
        assertThat(timeline.entries().get(1).toStatus()).isEqualTo(JobStatus.ACCEPTED.name());
    }

    @Test
    void shouldCancelJobFromAnyState() {
        CreateCaseResponse caseResp = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-005", "Rua Cancelamento, 1", "RESIDENTIAL",
                null, "Vistoria Cancelada"
        ));
        Long jobId = caseResp.jobId();

        JobSummaryResponse cancelled = jobService.cancelJob(TENANT_ID, jobId, "Solicitação do cliente", "admin-1");

        assertThat(cancelled.status()).isEqualTo(JobStatus.CLOSED.name());

        JobTimelineResponse timeline = jobService.getTimeline(TENANT_ID, jobId);
        assertThat(timeline.entries()).hasSize(1);
        assertThat(timeline.entries().get(0).toStatus()).isEqualTo(JobStatus.CLOSED.name());
        assertThat(timeline.entries().get(0).reason()).isEqualTo("Solicitação do cliente");
    }

    @Test
    void shouldReturnJobDetailWithAssignments() {
        CreateCaseResponse caseResp = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-006", "Rua Detalhe, 7", "RESIDENTIAL",
                null, "Vistoria Detalhe"
        ));
        Long jobId = caseResp.jobId();
        jobService.assignJob(TENANT_ID, jobId, new AssignJobRequest(operatorUserId), "admin-1");

        JobDetailResponse detail = jobService.getJobDetail(TENANT_ID, jobId);

        assertThat(detail.id()).isEqualTo(jobId);
        assertThat(detail.status()).isEqualTo(JobStatus.OFFERED.name());
        assertThat(detail.assignments()).hasSize(1);
        assertThat(detail.assignments().get(0).userId()).isEqualTo(operatorUserId);
    }

    @Test
    void shouldRejectInvalidTransition() {
        CreateCaseResponse caseResp = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-007", "Rua Invalida, 0", "RESIDENTIAL",
                null, "Transição Inválida"
        ));
        Long jobId = caseResp.jobId();

        // Cannot accept before assigning (ELIGIBLE_FOR_DISPATCH → ACCEPTED is invalid)
        assertThatThrownBy(() -> jobService.acceptJob(TENANT_ID, jobId, "actor-1"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Transição inválida");
    }

    @Test
    void shouldReturnMobileJobsForAssignedUser() {
        CreateCaseResponse caseResp = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-008", "Rua Mobile, 42", "RESIDENTIAL",
                null, "Vistoria Mobile"
        ));
        jobService.assignJob(TENANT_ID, caseResp.jobId(), new AssignJobRequest(operatorUserId), "admin-1");
        jobService.acceptJob(TENANT_ID, caseResp.jobId(), String.valueOf(operatorUserId));

        var mobileJobs = jobService.getMobileJobsForUser(TENANT_ID, operatorUserId, "ACCEPTED");

        assertThat(mobileJobs).hasSize(1);
        assertThat(mobileJobs.get(0).assignedTo()).isEqualTo(operatorUserId);
        assertThat(mobileJobs.get(0).status()).isEqualTo(JobStatus.ACCEPTED.name());
    }

    @Test
    void shouldIsolateMobileJobsByTenant() {
        String otherTenantId = "tenant-job-other";
        tenantRepository.save(new Tenant(otherTenantId, "tenant-job-other", "Tenant Other", TenantStatus.ACTIVE));

        CreateCaseResponse tenantA = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-009", "Rua Tenant A, 1", "RESIDENTIAL", null, "Job Tenant A"
        ));
        CreateCaseResponse tenantB = caseService.createCase(otherTenantId, "admin-1", new CreateCaseRequest(
                "CASE-010", "Rua Tenant B, 2", "RESIDENTIAL", null, "Job Tenant B"
        ));

        jobService.assignJob(TENANT_ID, tenantA.jobId(), new AssignJobRequest(operatorUserId), "admin-1");
        jobService.acceptJob(TENANT_ID, tenantA.jobId(), String.valueOf(operatorUserId));

        jobService.assignJob(otherTenantId, tenantB.jobId(), new AssignJobRequest(operatorUserId), "admin-1");
        jobService.acceptJob(otherTenantId, tenantB.jobId(), String.valueOf(operatorUserId));

        var tenantAJobs = jobService.getMobileJobsForUser(TENANT_ID, operatorUserId, "ACCEPTED");

        assertThat(tenantAJobs).hasSize(1);
        assertThat(tenantAJobs.get(0).tenantId()).isEqualTo(TENANT_ID);
    }
}
