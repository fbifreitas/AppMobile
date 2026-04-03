package com.appbackoffice.api.config.dto;

import java.util.List;

public record ConfigPackagesResponse(
        List<ConfigPackageResponse> items,
        int count,
        String generatedAt
) {
}