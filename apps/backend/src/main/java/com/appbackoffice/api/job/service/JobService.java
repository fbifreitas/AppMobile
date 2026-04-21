package com.appbackoffice.api.job.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.identity.service.TenantGuardService;
import com.appbackoffice.api.job.dto.AssignJobRequest;
import com.appbackoffice.api.job.dto.JobDetailResponse;
import com.appbackoffice.api.job.dto.JobSummaryResponse;
import com.appbackoffice.api.job.dto.JobTimelineResponse;
import com.appbackoffice.api.job.entity.Assignment;
import com.appbackoffice.api.job.entity.AssignmentResponse;
import com.appbackoffice.api.job.entity.InspectionCase;
import com.appbackoffice.api.job.entity.Job;
import com.appbackoffice.api.job.entity.JobStatus;
import com.appbackoffice.api.job.entity.JobTimelineEntry;
import com.appbackoffice.api.job.service.JobClientAbsentEvidenceService.ClientAbsentEvidenceCommand;
import com.appbackoffice.api.job.service.JobClientAbsentEvidenceService.StoredClientAbsentEvidence;
import com.appbackoffice.api.job.repository.AssignmentRepository;
import com.appbackoffice.api.job.repository.CaseRepository;
import com.appbackoffice.api.job.repository.JobRepository;
import com.appbackoffice.api.job.repository.JobTimelineRepository;
import com.appbackoffice.api.platform.entity.TenantApplicationEntity;
import com.appbackoffice.api.platform.repository.TenantApplicationRepository;
import com.appbackoffice.api.user.repository.UserRepository;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Locale;

@Service
public class JobService {

    private final JobRepository jobRepository;
    private final AssignmentRepository assignmentRepository;
    private final JobTimelineRepository timelineRepository;
    private final JobStateMachine stateMachine;
    private final CaseRepository caseRepository;
    private final TenantApplicationRepository tenantApplicationRepository;
    private final UserRepository userRepository;
    private final TenantGuardService tenantGuardService;
    private final JobClientAbsentEvidenceService jobClientAbsentEvidenceService;

    public JobService(JobRepository jobRepository,
                      AssignmentRepository assignmentRepository,
                      JobTimelineRepository timelineRepository,
                      JobStateMachine stateMachine,
                      CaseRepository caseRepository,
                      TenantApplicationRepository tenantApplicationRepository,
                      UserRepository userRepository,
                      TenantGuardService tenantGuardService,
                      JobClientAbsentEvidenceService jobClientAbsentEvidenceService) {
        this.jobRepository = jobRepository;
        this.assignmentRepository = assignmentRepository;
        this.timelineRepository = timelineRepository;
        this.stateMachine = stateMachine;
        this.caseRepository = caseRepository;
        this.tenantApplicationRepository = tenantApplicationRepository;
        this.userRepository = userRepository;
        this.tenantGuardService = tenantGuardService;
        this.jobClientAbsentEvidenceService = jobClientAbsentEvidenceService;
    }

    public Page<JobSummaryResponse> listJobs(String tenantId, String status, Pageable pageable) {
        tenantGuardService.requireActiveTenant(tenantId);
        Page<Job> page;
        if (status != null && !status.isBlank()) {
            JobStatus jobStatus = parseStatus(status);
            page = jobRepository.findByTenantIdAndStatus(tenantId, jobStatus, pageable);
        } else {
            page = jobRepository.findByTenantId(tenantId, pageable);
        }
        return page.map(this::toSummary);
    }

    public JobDetailResponse getJobDetail(String tenantId, Long jobId) {
        tenantGuardService.requireActiveTenant(tenantId);
        Job job = requireJobInTenant(tenantId, jobId);
        List<Assignment> assignments = assignmentRepository.findByJobId(jobId);
        return toDetail(job, assignments);
    }

    public JobTimelineResponse getTimeline(String tenantId, Long jobId) {
        tenantGuardService.requireActiveTenant(tenantId);
        requireJobInTenant(tenantId, jobId);
        List<JobTimelineEntry> entries = timelineRepository.findByJobIdOrderByOccurredAtAsc(jobId);
        List<JobTimelineResponse.TimelineEntry> mapped = entries.stream()
                .map(e -> new JobTimelineResponse.TimelineEntry(
                        e.getFromStatus(), e.getToStatus(), e.getActorId(), e.getReason(), e.getOccurredAt()))
                .toList();
        return new JobTimelineResponse(jobId, mapped);
    }

    @Transactional
    public JobSummaryResponse assignJob(String tenantId, Long jobId, AssignJobRequest request, String actorId) {
        tenantGuardService.requireActiveTenant(tenantId);
        Job job = requireJobInTenant(tenantId, jobId);
        requireAssignableUserInTenant(tenantId, request.userId());
        JobStatus from = job.getStatus();
        JobStatus nextStatus = resolveDispatchStatus(tenantId);
        stateMachine.validateTransition(from, nextStatus);

        Assignment assignment = new Assignment(jobId, request.userId(), tenantId);
        if (nextStatus == JobStatus.ACCEPTED) {
            assignment.respond(AssignmentResponse.ACCEPTED);
        }
        assignmentRepository.save(assignment);

        job.setStatus(nextStatus);
        job.setAssignedTo(request.userId());
        jobRepository.save(job);

        recordTimeline(job, from, nextStatus, actorId, dispatchReason(nextStatus));
        return toSummary(job);
    }

    @Transactional
    public JobSummaryResponse acceptJob(String tenantId, Long jobId, String actorId) {
        tenantGuardService.requireActiveTenant(tenantId);
        Job job = requireJobInTenant(tenantId, jobId);
        requireAssignedActor(job, actorId);
        JobStatus from = job.getStatus();
        stateMachine.validateTransition(from, JobStatus.ACCEPTED);

        assignmentRepository.findTopByJobIdOrderByOfferedAtDesc(jobId)
                .ifPresent(a -> a.respond(AssignmentResponse.ACCEPTED));

        job.setStatus(JobStatus.ACCEPTED);
        jobRepository.save(job);

        recordTimeline(job, from, JobStatus.ACCEPTED, actorId, null);
        return toSummary(job);
    }

    @Transactional
    public JobSummaryResponse cancelJob(String tenantId, Long jobId, String reason, String actorId) {
        tenantGuardService.requireActiveTenant(tenantId);
        Job job = requireJobInTenant(tenantId, jobId);
        JobStatus from = job.getStatus();
        stateMachine.validateTransition(from, JobStatus.CLOSED);

        job.setStatus(JobStatus.CLOSED);
        jobRepository.save(job);

        recordTimeline(job, from, JobStatus.CLOSED, actorId, reason);
        return toSummary(job);
    }

    @Transactional
    public JobSummaryResponse requestSchedulingAfterClientAbsent(
            String tenantId,
            Long jobId,
            String actorId,
            String reason,
            String responderName,
            ClientAbsentEvidenceCommand evidence
    ) {
        tenantGuardService.requireActiveTenant(tenantId);
        Job job = requireJobInTenant(tenantId, jobId);
        requireAssignedActor(job, actorId);

        StoredClientAbsentEvidence storedEvidence = jobClientAbsentEvidenceService.store(
                tenantId,
                jobId,
                actorId,
                responderName,
                reason,
                evidence
        );

        if (job.getStatus() == JobStatus.AWAITING_SCHEDULING) {
            return toSummary(job);
        }

        JobStatus from = job.getStatus();
        stateMachine.validateTransition(from, JobStatus.AWAITING_SCHEDULING);

        job.setStatus(JobStatus.AWAITING_SCHEDULING);
        job.setAssignedTo(null);
        jobRepository.save(job);

        recordTimeline(
                job,
                from,
                JobStatus.AWAITING_SCHEDULING,
                actorId,
                normalizeSchedulingReason(reason, responderName, storedEvidence)
        );
        return toSummary(job);
    }

    @Transactional
    public void submitInspectionFromMobile(String tenantId, Long jobId, String actorId) {
        tenantGuardService.requireActiveTenant(tenantId);
        Job job = requireJobInTenant(tenantId, jobId);
        requireAssignedActor(job, actorId);

        if (job.getStatus() == JobStatus.SUBMITTED || job.getStatus() == JobStatus.CLOSED) {
            return;
        }

        if (job.getStatus() == JobStatus.ACCEPTED) {
            transition(job, JobStatus.IN_EXECUTION, actorId, "Execution started by mobile submission");
        }
        if (job.getStatus() == JobStatus.IN_EXECUTION) {
            transition(job, JobStatus.FIELD_COMPLETED, actorId, "Field work completed by mobile submission");
        }
        if (job.getStatus() == JobStatus.FIELD_COMPLETED) {
            transition(job, JobStatus.SUBMITTED, actorId, "Inspection submitted by mobile");
            return;
        }

        if (job.getStatus() != JobStatus.SUBMITTED) {
            throw new ApiContractException(
                    HttpStatus.CONFLICT,
                    "JOB_SUBMISSION_STATE_INVALID",
                    "Job cannot be submitted from the current state",
                    ErrorSeverity.ERROR,
                    "Submit the inspection only after the job is accepted and assigned to the same field operator.",
                    "jobId=" + job.getId() + ", status=" + job.getStatus()
            );
        }
    }

    public List<JobSummaryResponse> getMobileJobsForUser(String tenantId, Long userId, String statusFilter) {
        tenantGuardService.requireActiveTenant(tenantId);
        List<Job> jobs;
        if (statusFilter != null && !statusFilter.isBlank()) {
            JobStatus status = parseStatus(statusFilter);
            jobs = jobRepository.findByAssignedToAndTenantIdAndStatus(userId, tenantId, status);
        } else {
            jobs = jobRepository.findByAssignedToAndTenantIdAndStatus(userId, tenantId, JobStatus.ACCEPTED);
        }
        return jobs.stream().map(this::toSummary).toList();
    }

    // --- helpers ---

    private Job requireJobInTenant(String tenantId, Long jobId) {
        Job job = jobRepository.findById(jobId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Job nÃ£o encontrado: " + jobId));
        if (!tenantId.equals(job.getTenantId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Job nÃ£o pertence ao tenant informado");
        }
        return job;
    }

    private void recordTimeline(Job job, JobStatus from, JobStatus to, String actorId, String reason) {
        timelineRepository.save(new JobTimelineEntry(job.getId(), from, to, actorId, reason));
    }

    private void transition(Job job, JobStatus to, String actorId, String reason) {
        JobStatus from = job.getStatus();
        stateMachine.validateTransition(from, to);
        job.setStatus(to);
        jobRepository.save(job);
        recordTimeline(job, from, to, actorId, reason);
    }

    private void requireAssignableUserInTenant(String tenantId, Long userId) {
        User user = userRepository.findByTenantIdAndId(tenantId, userId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.FORBIDDEN,
                        "JOB_ASSIGNEE_TENANT_MISMATCH",
                        "Assigned user does not belong to the requested tenant",
                        ErrorSeverity.ERROR,
                        "Assign the job only to a user that belongs to the same tenant.",
                        "tenantId=" + tenantId + ", userId=" + userId
                ));

        if (user.getStatus() == UserStatus.APPROVED) {
            return;
        }

        throw new ApiContractException(
                HttpStatus.FORBIDDEN,
                "JOB_ASSIGNEE_NOT_APPROVED",
                "Assigned user is not approved for field work",
                ErrorSeverity.ERROR,
                "Approve the user before assigning operational jobs.",
                "tenantId=" + tenantId + ", userId=" + userId + ", status=" + user.getStatus()
        );
    }

    private void requireAssignedActor(Job job, String actorId) {
        if (job.getAssignedTo() == null) {
            throw new ApiContractException(
                    HttpStatus.CONFLICT,
                    "JOB_NOT_ASSIGNED",
                    "Job is not assigned to any field operator",
                    ErrorSeverity.ERROR,
                    "Assign the job before attempting to accept it.",
                    "jobId=" + job.getId()
            );
        }

        Long actorUserId;
        try {
            actorUserId = Long.parseLong(actorId);
        } catch (NumberFormatException exception) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "INVALID_ACTOR_ID",
                    "Actor id must be numeric for job acceptance",
                    ErrorSeverity.ERROR,
                    "Send the assigned internal user id when accepting the job.",
                    "actorId=" + actorId
            );
        }

        if (job.getAssignedTo().equals(actorUserId)) {
            User actor = userRepository.findByTenantIdAndId(job.getTenantId(), actorUserId)
                    .orElseThrow(() -> new ApiContractException(
                            HttpStatus.FORBIDDEN,
                            "JOB_ACTOR_TENANT_MISMATCH",
                            "Assigned actor does not belong to the requested tenant",
                            ErrorSeverity.ERROR,
                            "Use an operator identity from the same tenant as the job.",
                            "jobId=" + job.getId() + ", actorId=" + actorUserId
                    ));

            if (actor.getStatus() == UserStatus.APPROVED) {
                return;
            }

            throw new ApiContractException(
                    HttpStatus.FORBIDDEN,
                    "JOB_ACTOR_NOT_APPROVED",
                    "Assigned actor is not approved for field work",
                    ErrorSeverity.ERROR,
                    "Approve the assigned operator before accepting or submitting the job.",
                    "jobId=" + job.getId() + ", actorId=" + actorUserId + ", status=" + actor.getStatus()
            );
        }

        throw new ApiContractException(
                HttpStatus.FORBIDDEN,
                "JOB_ACCEPT_FORBIDDEN",
                "Only the assigned field operator can accept this job",
                ErrorSeverity.ERROR,
                "Use the same assigned operator identity when accepting the job.",
                "jobId=" + job.getId() + ", assignedTo=" + job.getAssignedTo() + ", actorId=" + actorUserId
        );
    }

    private JobStatus parseStatus(String rawStatus) {
        try {
            return JobStatus.valueOf(rawStatus.toUpperCase());
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Status de job invalido: " + rawStatus);
        }
    }

    private JobSummaryResponse toSummary(Job job) {
        InspectionCase inspectionCase = caseRepository.findByTenantIdAndId(job.getTenantId(), job.getCaseId())
                .orElse(null);
        return new JobSummaryResponse(
                job.getId(), job.getCaseId(), job.getTenantId(), job.getTitle(),
                job.getStatus().name(),
                job.getAssignedTo(),
                inspectionCase != null ? inspectionCase.getPropertyAddress() : null,
                inspectionCase != null ? inspectionCase.getPropertyLatitude() : null,
                inspectionCase != null ? inspectionCase.getPropertyLongitude() : null,
                inspectionCase != null ? inspectionCase.getInspectionType() : null,
                job.getDeadlineAt(),
                job.getCreatedAt(),
                null
        );
    }

    private JobDetailResponse toDetail(Job job, List<Assignment> assignments) {
        List<JobDetailResponse.AssignmentInfo> infos = assignments.stream()
                .map(a -> new JobDetailResponse.AssignmentInfo(
                        a.getUserId(), a.getOfferedAt(), a.getRespondedAt(),
                        a.getResponse() != null ? a.getResponse().name() : null))
                .toList();
        return new JobDetailResponse(
                job.getId(), job.getCaseId(), job.getTenantId(), job.getTitle(),
                job.getStatus().name(), job.getAssignedTo(), job.getDeadlineAt(),
                job.getCreatedAt(), job.getUpdatedAt(), infos
        );
    }

    private JobStatus resolveDispatchStatus(String tenantId) {
        TenantApplicationEntity application = tenantApplicationRepository.findByTenantId(tenantId).orElse(null);
        if (application == null) {
            return JobStatus.OFFERED;
        }

        String appCode = normalize(application.getAppCode());
        String brandName = normalize(application.getBrandName());
        if ("compass".equals(appCode) || "compass".equals(brandName)) {
            return JobStatus.ACCEPTED;
        }
        return JobStatus.OFFERED;
    }

    private String dispatchReason(JobStatus nextStatus) {
        if (nextStatus == JobStatus.ACCEPTED) {
            return "Direct assignment accepted by dispatch policy";
        }
        return null;
    }

    private String normalizeSchedulingReason(String reason,
                                            String responderName,
                                            StoredClientAbsentEvidence evidence) {
        String normalized = reason == null ? "" : reason.trim();
        String base = !normalized.isEmpty()
                ? normalized
                : "Client not present during step 1 check-in. Awaiting scheduling treatment.";
        StringBuilder builder = new StringBuilder(base);
        if (responderName != null && !responderName.trim().isEmpty()) {
            builder.append(" Responder: ").append(responderName.trim()).append('.');
        }
        if (evidence != null) {
            builder.append(" Evidence captured at ").append(evidence.capturedAt()).append('.');
            if (evidence.latitude() != null && evidence.longitude() != null) {
                builder.append(" Geo=(")
                        .append(evidence.latitude())
                        .append(", ")
                        .append(evidence.longitude())
                        .append(").");
            }
            builder.append(" Storage=").append(evidence.storageKey()).append('.');
        }
        return builder.toString();
    }

    private String normalize(String value) {
        if (value == null) {
            return "";
        }
        return value.trim().toLowerCase(Locale.ROOT);
    }
}
