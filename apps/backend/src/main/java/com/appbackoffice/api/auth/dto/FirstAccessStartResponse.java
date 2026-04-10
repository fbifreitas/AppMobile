package com.appbackoffice.api.auth.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record FirstAccessStartResponse(
        String challengeId,
        String deliveryHint,
        long expiresInSeconds,
        String debugOtp
) {
}
