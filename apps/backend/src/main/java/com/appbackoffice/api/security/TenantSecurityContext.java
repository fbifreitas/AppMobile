package com.appbackoffice.api.security;

import com.appbackoffice.api.identity.entity.MembershipRole;

import java.util.Set;

public record TenantSecurityContext(
        Long userId,
        String tenantId,
        Set<MembershipRole> roles
) {
}
