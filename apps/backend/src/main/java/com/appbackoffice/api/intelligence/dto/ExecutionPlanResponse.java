package com.appbackoffice.api.intelligence.dto;

import com.appbackoffice.api.intelligence.entity.ExecutionPlanStatus;
import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;

import java.time.Instant;

public record ExecutionPlanResponse(
        Long snapshotId,
        Long caseId,
        ExecutionPlanStatus status,
        Instant createdAt,
        Instant publishedAt,
        ExecutionPlanPayload plan
) {
}
