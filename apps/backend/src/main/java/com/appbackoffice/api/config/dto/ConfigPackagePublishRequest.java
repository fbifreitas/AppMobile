package com.appbackoffice.api.config.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record ConfigPackagePublishRequest(
        @NotBlank String actorId,
        @NotBlank String actorRole,
        @NotBlank String scope,
        @NotBlank String tenantId,
        @Valid TargetSelectorDto selector,
        @Valid RolloutPolicyDto rollout,
        @NotNull @Valid ConfigRulesDto rules
) {
}