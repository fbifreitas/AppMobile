package com.appaigateway.dto;

public record ResearchFactResponse(
        String key,
        String value,
        double confidence,
        String source,
        String rationale
) {
}
