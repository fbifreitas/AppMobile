package com.appbackoffice.api.config.dto;

import java.util.List;

public record ConfigResolveResultResponse(
        ConfigRulesDto effective,
        List<ConfigPackageResponse> appliedPackages,
        List<ConfigPackageResponse> skippedPackages
) {
}