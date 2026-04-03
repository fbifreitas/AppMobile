package com.appbackoffice.api.job.dto;

import java.time.Instant;

public record JobSummaryResponse(
        Long id,
        Long caseId,
        String tenantId,
        String title,
        String status,
        Long assignedTo,
        Instant deadlineAt,
        Instant createdAt
) {
}
