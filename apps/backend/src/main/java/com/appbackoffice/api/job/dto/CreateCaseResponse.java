package com.appbackoffice.api.job.dto;

import java.time.Instant;

public record CreateCaseResponse(
        Long caseId,
        String caseNumber,
        Long jobId,
        String jobStatus,
        Instant createdAt
) {
}
