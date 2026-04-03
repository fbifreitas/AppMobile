package com.appbackoffice.api.config.dto;

public record ConfigPackageResponse(
        String id,
        String scope,
        String tenantId,
        String status,
        String updatedAt,
        TargetSelectorDto selector,
        RolloutPolicyDto rollout,
        ConfigRulesDto rules
) {
}