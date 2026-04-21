package com.appbackoffice.api.job.dto;

import com.appbackoffice.api.intelligence.dto.ExecutionPlanResponse;

import java.time.Instant;

public record JobSummaryResponse(
        Long id,
        Long caseId,
        String tenantId,
        String title,
        String status,
        Long assignedTo,
        String propertyAddress,
        Double propertyLatitude,
        Double propertyLongitude,
        String inspectionType,
        Instant deadlineAt,
        Instant createdAt,
        ExecutionPlanResponse executionPlan
) {
}
