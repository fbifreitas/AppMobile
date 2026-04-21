package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.intelligence.dto.ExecutionPlanResponse;
import com.appbackoffice.api.intelligence.entity.ExecutionPlanSnapshotEntity;
import com.appbackoffice.api.intelligence.repository.ExecutionPlanSnapshotRepository;
import com.appbackoffice.api.job.entity.Job;
import com.appbackoffice.api.job.repository.JobRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class ExecutionPlanQueryService {

    private final ExecutionPlanSnapshotRepository snapshotRepository;
    private final JobRepository jobRepository;
    private final ExecutionPlanPayloadMapper executionPlanPayloadMapper;

    public ExecutionPlanQueryService(ExecutionPlanSnapshotRepository snapshotRepository,
                                     JobRepository jobRepository,
                                     ExecutionPlanPayloadMapper executionPlanPayloadMapper) {
        this.snapshotRepository = snapshotRepository;
        this.jobRepository = jobRepository;
        this.executionPlanPayloadMapper = executionPlanPayloadMapper;
    }

    public ExecutionPlanResponse getLatestExecutionPlan(String tenantId, Long caseId) {
        return toResponse(requireLatestSnapshotForCase(tenantId, caseId));
    }

    public ExecutionPlanResponse getLatestExecutionPlanForJob(String tenantId, Long jobId) {
        Job job = jobRepository.findById(jobId)
                .filter(candidate -> tenantId.equals(candidate.getTenantId()))
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "JOB_NOT_FOUND",
                        "Job not found for the informed tenant",
                        ErrorSeverity.ERROR,
                        "Provide a valid job identifier for the current tenant.",
                        "jobId=" + jobId
                ));
        return getLatestExecutionPlan(tenantId, job.getCaseId());
    }

    public ExecutionPlanResponse getLatestExecutionPlanOrNull(String tenantId, Long caseId) {
        return snapshotRepository.findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(tenantId, caseId)
                .map(this::toResponse)
                .orElse(null);
    }

    private ExecutionPlanSnapshotEntity requireLatestSnapshotForCase(String tenantId, Long caseId) {
        return snapshotRepository.findTopByTenantIdAndCaseIdOrderByCreatedAtDesc(tenantId, caseId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "EXECUTION_PLAN_NOT_FOUND",
                        "No execution plan found for the informed case",
                        ErrorSeverity.ERROR,
                        "Trigger enrichment before requesting the latest execution plan.",
                        "caseId=" + caseId
                ));
    }

    private ExecutionPlanResponse toResponse(ExecutionPlanSnapshotEntity snapshot) {
        return new ExecutionPlanResponse(
                snapshot.getId(),
                snapshot.getCaseId(),
                snapshot.getStatus(),
                snapshot.getCreatedAt(),
                snapshot.getPublishedAt(),
                executionPlanPayloadMapper.read(snapshot.getPlanJson())
        );
    }
}
