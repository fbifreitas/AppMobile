package com.appbackoffice.api.intelligence.port;

public record ResearchFact(
        String key,
        String value,
        double confidence,
        String source,
        String rationale
) {
}
