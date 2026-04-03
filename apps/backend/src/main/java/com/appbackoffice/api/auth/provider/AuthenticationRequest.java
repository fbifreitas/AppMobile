package com.appbackoffice.api.auth.provider;

public record AuthenticationRequest(
        String tenantId,
        String email,
        String password
) {
}
