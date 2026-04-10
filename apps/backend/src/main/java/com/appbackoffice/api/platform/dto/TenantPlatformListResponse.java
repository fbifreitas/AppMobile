package com.appbackoffice.api.platform.dto;

import java.time.Instant;
import java.util.List;

public record TenantPlatformListResponse(
        Instant generatedAt,
        int total,
        List<TenantPlatformSummaryResponse> items
) {
}
