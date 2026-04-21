package com.appbackoffice.api.mobile.service;

import com.appbackoffice.api.intelligence.dto.ExecutionPlanResponse;
import com.appbackoffice.api.intelligence.service.ExecutionPlanQueryService;
import com.appbackoffice.api.job.dto.JobSummaryResponse;
import com.appbackoffice.api.job.service.JobService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MobileJobQueryService {

    private final JobService jobService;
    private final ExecutionPlanQueryService executionPlanQueryService;

    public MobileJobQueryService(JobService jobService,
                                 ExecutionPlanQueryService executionPlanQueryService) {
        this.jobService = jobService;
        this.executionPlanQueryService = executionPlanQueryService;
    }

    public List<JobSummaryResponse> listJobs(String tenantId, Long userId, String statusFilter) {
        return jobService.getMobileJobsForUser(tenantId, userId, statusFilter).stream()
                .map(job -> new JobSummaryResponse(
                        job.id(),
                        job.caseId(),
                        job.tenantId(),
                        job.title(),
                        job.status(),
                        job.assignedTo(),
                        job.propertyAddress(),
                        job.propertyLatitude(),
                        job.propertyLongitude(),
                        job.inspectionType(),
                        job.deadlineAt(),
                        job.createdAt(),
                        executionPlanOrNull(tenantId, job.caseId())
                ))
                .toList();
    }

    private ExecutionPlanResponse executionPlanOrNull(String tenantId, Long caseId) {
        return executionPlanQueryService.getLatestExecutionPlanOrNull(tenantId, caseId);
    }
}
