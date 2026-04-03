package com.appbackoffice.api.policy;

import com.appbackoffice.api.identity.entity.MembershipRole;
import org.springframework.stereotype.Component;

import java.util.Set;

@Component
public class JobAccessPolicy implements DomainPolicy<JobAccessPolicy.JobResource> {

    @Override
    public boolean isAllowed(String actorId, String tenantId, String action, JobResource resource) {
        if (resource == null || action == null) {
            return false;
        }

        if (!tenantId.equals(resource.tenantId())) {
            return false;
        }

        return switch (action) {
            case "VIEW" -> {
                if (resource.actorRoles().contains(MembershipRole.FIELD_OPERATOR)) {
                    yield actorId != null && actorId.equals(resource.assignedTo());
                }
                yield resource.actorRoles().stream().anyMatch(role ->
                        role == MembershipRole.COORDINATOR
                                || role == MembershipRole.TENANT_ADMIN
                                || role == MembershipRole.AUDITOR
                                || role == MembershipRole.PLATFORM_ADMIN
                );
            }
            case "DISPATCH" -> resource.actorRoles().stream().anyMatch(role ->
                    role == MembershipRole.COORDINATOR
                            || role == MembershipRole.TENANT_ADMIN
                            || role == MembershipRole.PLATFORM_ADMIN
            );
            default -> false;
        };
    }

    public record JobResource(
            String tenantId,
            String assignedTo,
            Set<MembershipRole> actorRoles
    ) {
    }
}
