package com.appbackoffice.api.auth.provider;

public record AuthenticatedIdentity(
        Long userId,
        String tenantId,
        String email
) {
}
