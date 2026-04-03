package com.appbackoffice.api.job.dto;

import java.time.Instant;
import java.util.List;

public record JobTimelineResponse(
        Long jobId,
        List<TimelineEntry> entries
) {
    public record TimelineEntry(String fromStatus, String toStatus, String actorId, String reason, Instant occurredAt) {
    }
}
