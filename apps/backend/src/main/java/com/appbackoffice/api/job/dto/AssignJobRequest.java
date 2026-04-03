package com.appbackoffice.api.job.dto;

import jakarta.validation.constraints.NotNull;

public record AssignJobRequest(
        @NotNull Long userId
) {
}
