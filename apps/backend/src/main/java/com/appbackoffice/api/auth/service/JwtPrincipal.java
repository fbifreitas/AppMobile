package com.appbackoffice.api.auth.service;

import java.time.Instant;
import java.util.List;

public record JwtPrincipal(
        Long userId,
        String tenantId,
        String organizationUnitId,
        List<String> roles,
        Instant expiresAt,
        String tokenId
) {
}
