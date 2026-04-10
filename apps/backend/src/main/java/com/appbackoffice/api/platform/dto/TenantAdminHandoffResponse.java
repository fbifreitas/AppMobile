package com.appbackoffice.api.platform.dto;

import com.appbackoffice.api.user.dto.UserResponse;

import java.time.Instant;

public record TenantAdminHandoffResponse(
        String tenantId,
        UserResponse adminUser,
        boolean credentialProvisioned,
        Instant credentialUpdatedAt,
        String temporaryPassword
) {
}
