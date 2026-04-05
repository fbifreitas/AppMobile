package com.appbackoffice.api.config.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.List;

public record ConfigCheckinSectionRuleDto(
        @NotBlank String sectionKey,
        @NotBlank String sectionLabel,
        @NotNull Boolean mandatory,
        @NotNull Integer photoMin,
        @NotNull Integer photoMax,
        List<String> desiredItems,
        String tipoImovel,
        Integer sortOrder
) {
}
