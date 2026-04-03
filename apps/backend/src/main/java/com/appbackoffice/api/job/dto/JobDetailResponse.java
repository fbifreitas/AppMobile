package com.appbackoffice.api.job.dto;

import java.time.Instant;
import java.util.List;

public record JobDetailResponse(
        Long id,
        Long caseId,
        String tenantId,
        String title,
        String status,
        Long assignedTo,
        Instant deadlineAt,
        Instant createdAt,
        Instant updatedAt,
        List<AssignmentInfo> assignments
) {
    public record AssignmentInfo(Long userId, Instant offeredAt, Instant respondedAt, String response) {
    }
}
