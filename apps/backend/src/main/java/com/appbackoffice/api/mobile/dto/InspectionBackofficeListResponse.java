package com.appbackoffice.api.mobile.dto;

import java.time.Instant;
import java.util.List;

public record InspectionBackofficeListResponse(
        int page,
        int size,
        long total,
        Summary summary,
        List<Item> items
) {
    public record Summary(
            long receivedToday,
            long pendingIntake,
            long syncErrors,
            long submitted
    ) {
    }

    public record Item(
            Long id,
            Long jobId,
            Long vistoriadorId,
            String protocolId,
            String status,
            Instant submittedAt,
            Instant updatedAt
    ) {
    }
}
