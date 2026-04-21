package com.appbackoffice.api.intelligence.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ManualSubtypeResolutionRequest(
        @NotBlank
        String assetSubtype,
        @Size(max = 500)
        String note
) {
}
