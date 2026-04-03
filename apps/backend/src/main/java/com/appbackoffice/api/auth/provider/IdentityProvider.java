package com.appbackoffice.api.auth.provider;

public interface IdentityProvider {
    AuthenticatedIdentity authenticate(AuthenticationRequest request);

    AuthenticatedIdentity resolveIdentity(String providerToken, String tenantId);

    void revokeSession(String sessionId);
}
