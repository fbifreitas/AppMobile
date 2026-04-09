package com.appbackoffice.api.observability.dto;

import java.time.Instant;

public record RetentionExecutionResponse(
        Instant executedAt,
        int retentionDays,
        long deletedEvents
) {
}
