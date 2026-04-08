package com.appbackoffice.api.mobile.dto;

import java.time.Instant;

public record InspectionFinalizedResponse(
        String protocolId,
        String processId,
        String processNumber,
        Long jobId,
        Instant receivedAt,
        String status,
        boolean duplicate
) {
}
