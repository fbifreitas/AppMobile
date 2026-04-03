package com.appbackoffice.api.auth.service;

import com.appbackoffice.api.identity.entity.MembershipRole;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class PermissionCatalog {

    public List<String> permissionsFor(MembershipRole role) {
        return switch (role) {
            case PLATFORM_ADMIN -> List.of("platform:*", "tenant:*", "users:*", "config:*", "jobs:*");
            case TENANT_ADMIN -> List.of("tenant:manage", "users:manage", "config:publish", "config:approve", "jobs:view");
            case COORDINATOR, REGIONAL_COORD -> List.of("users:view", "jobs:assign", "jobs:view", "config:view");
            case OPERATOR -> List.of("jobs:view", "jobs:update", "config:view");
            case AUDITOR -> List.of("users:view", "jobs:view", "config:view");
            case FIELD_OPERATOR -> List.of("jobs:view", "jobs:execute", "mobile:sync");
        };
    }
}
