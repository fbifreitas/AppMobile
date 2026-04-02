package com.appbackoffice.api.mobile.dto;

import java.time.Instant;

public record InspectionFinalizedResponse(
        String protocolId,
        Instant receivedAt,
        String status,
        boolean duplicate
) {
}
