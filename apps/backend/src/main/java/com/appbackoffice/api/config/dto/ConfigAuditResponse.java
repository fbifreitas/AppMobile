package com.appbackoffice.api.config.dto;

import java.util.List;

public record ConfigAuditResponse(
        List<ConfigAuditEntryResponse> items,
        int count,
        String generatedAt
) {
}