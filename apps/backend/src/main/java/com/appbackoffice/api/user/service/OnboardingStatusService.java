package com.appbackoffice.api.user.service;

import com.appbackoffice.api.platform.repository.TenantApplicationRepository;
import com.appbackoffice.api.user.dto.OnboardingPendingResponse;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserLifecycleStatus;
import com.appbackoffice.api.user.entity.UserSource;
import com.appbackoffice.api.user.entity.UserStatus;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@Service
public class OnboardingStatusService {

    private final TenantApplicationRepository tenantApplicationRepository;

    public OnboardingStatusService(TenantApplicationRepository tenantApplicationRepository) {
        this.tenantApplicationRepository = tenantApplicationRepository;
    }

    public OnboardingPendingResponse build(User user) {
        String appCode = tenantApplicationRepository.findByTenantId(user.getTenantId())
                .map(entity -> entity.getAppCode())
                .filter(value -> value != null && !value.isBlank())
                .orElse("default");

        String policy = resolvePolicy(appCode, user);
        List<String> pendingSteps = resolvePendingSteps(policy, user);
        boolean awaitingApproval = user.getStatus() == UserStatus.AWAITING_APPROVAL
                || (user.getLifecycle() != null && user.getLifecycle().getStatus() == UserLifecycleStatus.PENDING_APPROVAL);

        return new OnboardingPendingResponse(
                user.getId(),
                user.getTenantId(),
                appCode,
                policy,
                pendingSteps.isEmpty(),
                awaitingApproval,
                List.copyOf(pendingSteps)
        );
    }

    private String resolvePolicy(String appCode, User user) {
        String normalized = appCode.trim().toLowerCase(Locale.ROOT);
        if ("compass".equals(normalized)) {
            return "corporate_first_access";
        }
        if ("kaptur".equals(normalized) || "kaptu".equals(normalized)) {
            return "marketplace_provider";
        }
        if (user.getSource() == UserSource.MOBILE_ONBOARDING) {
            return "marketplace_provider";
        }
        return "corporate_first_access";
    }

    private List<String> resolvePendingSteps(String policy, User user) {
        List<String> steps = new ArrayList<>();
        boolean awaitingApproval = user.getStatus() == UserStatus.AWAITING_APPROVAL
                || (user.getLifecycle() != null && user.getLifecycle().getStatus() == UserLifecycleStatus.PENDING_APPROVAL);

        if ("corporate_first_access".equals(policy)) {
            if (user.getBirthDate() == null || isBlank(user.getCpf()) || isBlank(user.getExternalId())) {
                steps.add("identity_validation");
            }
            if (awaitingApproval) {
                steps.add("awaiting_approval");
            }
            steps.add("selfie");
            steps.add("terms");
            steps.add("permissions");
            return dedupe(steps);
        }

        if (isBlank(user.getCpf()) && isBlank(user.getCnpj())) {
            steps.add("identity");
        }
        if (isBlank(user.getNome())) {
            steps.add("profile");
        }
        if (awaitingApproval) {
            steps.add("awaiting_approval");
        }
        steps.add("terms");
        steps.add("permissions");
        return dedupe(steps);
    }

    private List<String> dedupe(List<String> steps) {
        return steps.stream().distinct().toList();
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
