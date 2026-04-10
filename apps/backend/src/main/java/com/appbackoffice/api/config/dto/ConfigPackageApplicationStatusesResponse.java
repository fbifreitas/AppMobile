package com.appbackoffice.api.config.dto;

import java.util.List;

public record ConfigPackageApplicationStatusesResponse(
        List<ConfigPackageApplicationStatusResponse> items,
        int total,
        String generatedAt
) {
}
