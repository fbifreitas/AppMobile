package com.appbackoffice.api.user.dto;

import java.util.List;

public record OnboardingPendingResponse(
        Long userId,
        String tenantId,
        String appCode,
        String onboardingPolicy,
        boolean onboardingCompleted,
        boolean awaitingApproval,
        List<String> pendingSteps
) {
}
