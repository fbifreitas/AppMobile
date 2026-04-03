package com.appbackoffice.api.policy;

import com.appbackoffice.api.identity.entity.MembershipRole;
import org.springframework.stereotype.Component;

import java.util.Set;

@Component
public class UserAccessPolicy implements DomainPolicy<UserAccessPolicy.UserResource> {

    @Override
    public boolean isAllowed(String actorId, String tenantId, String action, UserResource resource) {
        if (resource == null || action == null) {
            return false;
        }

        if (!tenantId.equals(resource.tenantId())) {
            return false;
        }

        return switch (action) {
            case "VIEW", "LIST", "AUDIT" -> resource.actorRoles().stream().anyMatch(role ->
                    role == MembershipRole.TENANT_ADMIN
                            || role == MembershipRole.COORDINATOR
                            || role == MembershipRole.AUDITOR
                            || role == MembershipRole.PLATFORM_ADMIN
            );
            case "CREATE", "APPROVE", "REJECT", "IMPORT" -> resource.actorRoles().stream().anyMatch(role ->
                    role == MembershipRole.TENANT_ADMIN
                            || role == MembershipRole.COORDINATOR
                            || role == MembershipRole.PLATFORM_ADMIN
            );
            default -> false;
        };
    }

    public record UserResource(
            String tenantId,
            Set<MembershipRole> actorRoles
    ) {
    }
}
