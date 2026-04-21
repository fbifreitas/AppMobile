package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.port.ResearchFact;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Optional;

@Component
public class ResearchFactResolver {

    public Optional<String> firstValue(ResearchProviderResponse response, String... keys) {
        if (response == null || response.facts() == null || response.facts().isEmpty()) {
            return Optional.empty();
        }
        List<String> normalizedKeys = Arrays.stream(keys)
                .map(this::normalize)
                .toList();
        return response.facts().stream()
                .filter(Objects::nonNull)
                .filter(fact -> normalizedKeys.contains(normalize(fact.key())))
                .map(ResearchFact::value)
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(value -> !value.isEmpty())
                .findFirst();
    }

    public boolean containsText(ResearchProviderResponse response, String... fragments) {
        if (response == null || response.facts() == null || response.facts().isEmpty()) {
            return false;
        }
        List<String> normalizedFragments = Arrays.stream(fragments)
                .map(this::normalize)
                .toList();
        return response.facts().stream()
                .filter(Objects::nonNull)
                .flatMap(fact -> Arrays.stream(new String[]{fact.key(), fact.value(), fact.rationale()}))
                .filter(Objects::nonNull)
                .map(this::normalize)
                .anyMatch(text -> normalizedFragments.stream().anyMatch(text::contains));
    }

    private String normalize(String value) {
        String normalized = value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
        return Normalizer.normalize(normalized, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
    }
}
