package com.appbackoffice.api.job.service;

import com.appbackoffice.api.job.dto.AssignJobRequest;
import com.appbackoffice.api.job.dto.JobDetailResponse;
import com.appbackoffice.api.job.dto.JobSummaryResponse;
import com.appbackoffice.api.job.dto.JobTimelineResponse;
import com.appbackoffice.api.job.entity.Assignment;
import com.appbackoffice.api.job.entity.AssignmentResponse;
import com.appbackoffice.api.job.entity.Job;
import com.appbackoffice.api.job.entity.JobStatus;
import com.appbackoffice.api.job.entity.JobTimelineEntry;
import com.appbackoffice.api.job.repository.AssignmentRepository;
import com.appbackoffice.api.job.repository.JobRepository;
import com.appbackoffice.api.job.repository.JobTimelineRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class JobService {

    private final JobRepository jobRepository;
    private final AssignmentRepository assignmentRepository;
    private final JobTimelineRepository timelineRepository;
    private final JobStateMachine stateMachine;

    public JobService(JobRepository jobRepository,
                      AssignmentRepository assignmentRepository,
                      JobTimelineRepository timelineRepository,
                      JobStateMachine stateMachine) {
        this.jobRepository = jobRepository;
        this.assignmentRepository = assignmentRepository;
        this.timelineRepository = timelineRepository;
        this.stateMachine = stateMachine;
    }

    public Page<JobSummaryResponse> listJobs(String tenantId, String status, Pageable pageable) {
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
        Job job = requireJobInTenant(tenantId, jobId);
        List<Assignment> assignments = assignmentRepository.findByJobId(jobId);
        return toDetail(job, assignments);
    }

    public JobTimelineResponse getTimeline(String tenantId, Long jobId) {
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
        Job job = requireJobInTenant(tenantId, jobId);
        JobStatus from = job.getStatus();
        stateMachine.validateTransition(from, JobStatus.OFFERED);

        Assignment assignment = new Assignment(jobId, request.userId(), tenantId);
        assignmentRepository.save(assignment);

        job.setStatus(JobStatus.OFFERED);
        job.setAssignedTo(request.userId());
        jobRepository.save(job);

        recordTimeline(job, from, JobStatus.OFFERED, actorId, null);
        return toSummary(job);
    }

    @Transactional
    public JobSummaryResponse acceptJob(String tenantId, Long jobId, String actorId) {
        Job job = requireJobInTenant(tenantId, jobId);
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
        Job job = requireJobInTenant(tenantId, jobId);
        JobStatus from = job.getStatus();
        stateMachine.validateTransition(from, JobStatus.CLOSED);

        job.setStatus(JobStatus.CLOSED);
        jobRepository.save(job);

        recordTimeline(job, from, JobStatus.CLOSED, actorId, reason);
        return toSummary(job);
    }

    @Transactional
    public void submitInspectionFromMobile(String tenantId, Long jobId, String actorId) {
        Job job = requireJobInTenant(tenantId, jobId);

        if (job.getStatus() == JobStatus.SUBMITTED || job.getStatus() == JobStatus.CLOSED) {
            return;
        }

        if (job.getStatus() == JobStatus.ACCEPTED) {
            transition(job, JobStatus.IN_EXECUTION, actorId, "Execucao iniciada pelo envio mobile");
        }
        if (job.getStatus() == JobStatus.IN_EXECUTION) {
            transition(job, JobStatus.FIELD_COMPLETED, actorId, "Campo concluido pelo envio mobile");
        }
        if (job.getStatus() == JobStatus.FIELD_COMPLETED) {
            transition(job, JobStatus.SUBMITTED, actorId, "Inspecao submetida pelo mobile");
            return;
        }

        if (job.getStatus() != JobStatus.SUBMITTED) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Job não pode ser submetido a partir do estado atual: " + job.getStatus());
        }
    }

    public List<JobSummaryResponse> getMobileJobsForUser(String tenantId, Long userId, String statusFilter) {
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
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Job não encontrado: " + jobId));
        if (!tenantId.equals(job.getTenantId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Job não pertence ao tenant informado");
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

    private JobStatus parseStatus(String rawStatus) {
        try {
            return JobStatus.valueOf(rawStatus.toUpperCase());
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Status de job invalido: " + rawStatus);
        }
    }

    private JobSummaryResponse toSummary(Job job) {
        return new JobSummaryResponse(
                job.getId(), job.getCaseId(), job.getTenantId(), job.getTitle(),
                job.getStatus().name(), job.getAssignedTo(), job.getDeadlineAt(), job.getCreatedAt()
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
}
