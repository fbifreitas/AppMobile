package com.appbackoffice.api.config.dto;

import java.util.List;

public record RolloutPolicyDto(
        String activation,
        String startsAt,
        String endsAt,
        List<String> batchUserIds
) {
}