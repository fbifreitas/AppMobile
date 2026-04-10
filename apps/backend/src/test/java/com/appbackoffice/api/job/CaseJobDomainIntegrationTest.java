package com.appbackoffice.api.job;

import com.appbackoffice.api.contract.ApiContractException;
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
import com.appbackoffice.api.platform.repository.TenantApplicationRepository;
import com.appbackoffice.api.platform.repository.TenantLicenseRepository;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserStatus;
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
    @Autowired private TenantApplicationRepository tenantApplicationRepository;
    @Autowired private TenantLicenseRepository tenantLicenseRepository;

    private Long operatorUserId;
    private Long otherTenantUserId;

    private void cleanAll() {
        timelineRepository.deleteAll();
        assignmentRepository.deleteAll();
        jobRepository.deleteAll();
        caseRepository.deleteAll();
        userRepository.deleteAll();
        tenantApplicationRepository.deleteAll();
        tenantLicenseRepository.deleteAll();
        tenantRepository.deleteAll();
    }

    @BeforeEach
    void setUp() {
        cleanAll();
        tenantRepository.save(new Tenant(TENANT_ID, "tenant-job-slug", "Tenant Job Test", TenantStatus.ACTIVE));
        User operator = userRepository.save(new User(TENANT_ID, "vistoriador@teste.com", "Vistoriador Teste", "PJ"));
        operator.setStatus(UserStatus.APPROVED);
        operator = userRepository.save(operator);
        operatorUserId = operator.getId();
        tenantRepository.save(new Tenant("tenant-job-external", "tenant-job-external", "Tenant External", TenantStatus.ACTIVE));
        User externalUser = userRepository.save(new User("tenant-job-external", "external@teste.com", "External Operator", "PJ"));
        externalUser.setStatus(UserStatus.APPROVED);
        externalUser = userRepository.save(externalUser);
        otherTenantUserId = externalUser.getId();
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

        JobSummaryResponse cancelled = jobService.cancelJob(TENANT_ID, jobId, "SolicitaÃƒÂ§ÃƒÂ£o do cliente", "admin-1");

        assertThat(cancelled.status()).isEqualTo(JobStatus.CLOSED.name());

        JobTimelineResponse timeline = jobService.getTimeline(TENANT_ID, jobId);
        assertThat(timeline.entries()).hasSize(1);
        assertThat(timeline.entries().get(0).toStatus()).isEqualTo(JobStatus.CLOSED.name());
        assertThat(timeline.entries().get(0).reason()).isEqualTo("SolicitaÃƒÂ§ÃƒÂ£o do cliente");
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
                null, "TransiÃƒÂ§ÃƒÂ£o InvÃƒÂ¡lida"
        ));
        Long jobId = caseResp.jobId();

        // Accepting before assignment must fail with the canonical domain error.
        assertThatThrownBy(() -> jobService.acceptJob(TENANT_ID, jobId, "actor-1"))
                .isInstanceOf(ApiContractException.class)
                .hasMessageContaining("Job is not assigned to any field operator");
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
        User otherTenantOperator = userRepository.save(new User(
                otherTenantId,
                "other-tenant-operator@teste.com",
                "Other Tenant Operator",
                "PJ"
        ));
        otherTenantOperator.setStatus(UserStatus.APPROVED);
        otherTenantOperator = userRepository.save(otherTenantOperator);

        CreateCaseResponse tenantA = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-009", "Rua Tenant A, 1", "RESIDENTIAL", null, "Job Tenant A"
        ));
        CreateCaseResponse tenantB = caseService.createCase(otherTenantId, "admin-1", new CreateCaseRequest(
                "CASE-010", "Rua Tenant B, 2", "RESIDENTIAL", null, "Job Tenant B"
        ));

        jobService.assignJob(TENANT_ID, tenantA.jobId(), new AssignJobRequest(operatorUserId), "admin-1");
        jobService.acceptJob(TENANT_ID, tenantA.jobId(), String.valueOf(operatorUserId));

        jobService.assignJob(otherTenantId, tenantB.jobId(), new AssignJobRequest(otherTenantOperator.getId()), "admin-1");
        jobService.acceptJob(otherTenantId, tenantB.jobId(), String.valueOf(otherTenantOperator.getId()));

        var tenantAJobs = jobService.getMobileJobsForUser(TENANT_ID, operatorUserId, "ACCEPTED");

        assertThat(tenantAJobs).hasSize(1);
        assertThat(tenantAJobs.get(0).tenantId()).isEqualTo(TENANT_ID);
    }

    @Test
    void shouldRejectDuplicateCaseNumberInsideSameTenant() {
        caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-DUP-001", "Rua A, 1", "RESIDENTIAL", null, "Job A"
        ));

        assertThatThrownBy(() -> caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-DUP-001", "Rua B, 2", "RESIDENTIAL", null, "Job B"
        )))
                .isInstanceOf(com.appbackoffice.api.contract.ApiContractException.class)
                .hasMessageContaining("Case number already exists");
    }

    @Test
    void shouldAllowSameCaseNumberAcrossDifferentTenants() {
        String otherTenantId = "tenant-job-dup-other";
        tenantRepository.save(new Tenant(otherTenantId, "tenant-job-dup-other", "Tenant Other Dup", TenantStatus.ACTIVE));

        CreateCaseResponse tenantA = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-SHARED-001", "Rua A, 1", "RESIDENTIAL", null, "Job Tenant A"
        ));
        CreateCaseResponse tenantB = caseService.createCase(otherTenantId, "admin-1", new CreateCaseRequest(
                "CASE-SHARED-001", "Rua B, 2", "RESIDENTIAL", null, "Job Tenant B"
        ));

        assertThat(tenantA.caseId()).isNotEqualTo(tenantB.caseId());
        assertThat(tenantA.caseNumber()).isEqualTo("CASE-SHARED-001");
        assertThat(tenantB.caseNumber()).isEqualTo("CASE-SHARED-001");
    }

    @Test
    void shouldRejectAssignmentToUserFromDifferentTenant() {
        CreateCaseResponse caseResp = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-CROSS-USER-001", "Rua Tenant, 10", "RESIDENTIAL", null, "Cross Tenant Assignment"
        ));

        assertThatThrownBy(() -> jobService.assignJob(
                TENANT_ID,
                caseResp.jobId(),
                new AssignJobRequest(otherTenantUserId),
                "admin-1"
        ))
                .isInstanceOf(com.appbackoffice.api.contract.ApiContractException.class)
                .hasMessageContaining("Assigned user does not belong");
    }

    @Test
    void shouldRejectAcceptWhenActorIsNotAssignedOperator() {
        CreateCaseResponse caseResp = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-WRONG-ACTOR-001", "Rua Actor, 20", "RESIDENTIAL", null, "Wrong Actor"
        ));
        jobService.assignJob(TENANT_ID, caseResp.jobId(), new AssignJobRequest(operatorUserId), "admin-1");

        assertThatThrownBy(() -> jobService.acceptJob(TENANT_ID, caseResp.jobId(), String.valueOf(otherTenantUserId)))
                .isInstanceOf(com.appbackoffice.api.contract.ApiContractException.class)
                .hasMessageContaining("Only the assigned field operator can accept this job");
    }

    @Test
    void shouldRejectCaseCreationForInactiveTenant() {
        String suspendedTenantId = "tenant-job-suspended";
        tenantRepository.save(new Tenant(suspendedTenantId, suspendedTenantId, "Tenant Suspended", TenantStatus.SUSPENDED));

        assertThatThrownBy(() -> caseService.createCase(suspendedTenantId, "admin-1", new CreateCaseRequest(
                "CASE-SUSPENDED-001", "Rua Suspended, 1", "RESIDENTIAL", null, "Suspended Tenant Job"
        )))
                .isInstanceOf(ApiContractException.class)
                .hasMessageContaining("Tenant is not active");
    }

    @Test
    void shouldRejectJobOperationsForInactiveTenant() {
        String suspendedTenantId = "tenant-job-suspended-ops";
        tenantRepository.save(new Tenant(suspendedTenantId, suspendedTenantId, "Tenant Suspended Ops", TenantStatus.ACTIVE));
        User suspendedTenantOperator = userRepository.save(new User(
                suspendedTenantId,
                "suspended-operator@teste.com",
                "Suspended Operator",
                "PJ"
        ));
        CreateCaseResponse suspendedCase = caseService.createCase(suspendedTenantId, "admin-1", new CreateCaseRequest(
                "CASE-SUSPENDED-OPS-001", "Rua Suspended, 2", "RESIDENTIAL", null, "Suspended Ops Job"
        ));
        tenantRepository.findById(suspendedTenantId).ifPresent(tenant -> {
            tenant.setStatus(TenantStatus.SUSPENDED);
            tenantRepository.save(tenant);
        });

        assertThatThrownBy(() -> jobService.assignJob(
                suspendedTenantId,
                suspendedCase.jobId(),
                new AssignJobRequest(suspendedTenantOperator.getId()),
                "admin-1"
        ))
                .isInstanceOf(ApiContractException.class)
                .hasMessageContaining("Tenant is not active");

        assertThatThrownBy(() -> jobService.listJobs(suspendedTenantId, null, org.springframework.data.domain.PageRequest.of(0, 10)))
                .isInstanceOf(ApiContractException.class)
                .hasMessageContaining("Tenant is not active");
    }

    @Test
    void shouldRejectAssignmentToUserAwaitingApproval() {
        User pendingOperator = userRepository.save(new User(
                TENANT_ID,
                "pending-operator@teste.com",
                "Pending Operator",
                "PJ"
        ));

        CreateCaseResponse caseResp = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-PENDING-ASSIGNEE-001", "Rua Pending, 10", "RESIDENTIAL", null, "Pending Assignee"
        ));

        assertThatThrownBy(() -> jobService.assignJob(
                TENANT_ID,
                caseResp.jobId(),
                new AssignJobRequest(pendingOperator.getId()),
                "admin-1"
        ))
                .isInstanceOf(ApiContractException.class)
                .hasMessageContaining("Assigned user is not approved for field work");
    }

    @Test
    void shouldRejectAcceptWhenAssignedOperatorIsNotApproved() {
        User pendingOperator = userRepository.save(new User(
                TENANT_ID,
                "pending-accept@teste.com",
                "Pending Accept Operator",
                "PJ"
        ));
        pendingOperator.setStatus(UserStatus.APPROVED);
        pendingOperator = userRepository.save(pendingOperator);
        Long pendingOperatorId = pendingOperator.getId();

        CreateCaseResponse caseResp = caseService.createCase(TENANT_ID, "admin-1", new CreateCaseRequest(
                "CASE-PENDING-ACTOR-001", "Rua Pending Actor, 20", "RESIDENTIAL", null, "Pending Actor"
        ));
        jobService.assignJob(TENANT_ID, caseResp.jobId(), new AssignJobRequest(pendingOperatorId), "admin-1");

        pendingOperator.setStatus(UserStatus.AWAITING_APPROVAL);
        userRepository.save(pendingOperator);

        assertThatThrownBy(() -> jobService.acceptJob(TENANT_ID, caseResp.jobId(), String.valueOf(pendingOperatorId)))
                .isInstanceOf(ApiContractException.class)
                .hasMessageContaining("Assigned actor is not approved for field work");
    }
}
