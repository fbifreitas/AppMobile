package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class OperationalReferenceProfileCodec {

    private static final TypeReference<List<String>> STRING_LIST = new TypeReference<>() {
    };
    private static final TypeReference<List<ExecutionPlanPayload.CameraEnvironmentProfile>> COMPOSITION_LIST =
            new TypeReference<>() {
            };

    private final ObjectMapper objectMapper;

    public OperationalReferenceProfileCodec(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public String writeStringList(List<String> items) {
        return write(items == null ? List.of() : items);
    }

    public List<String> readStringList(String raw) {
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(raw, STRING_LIST);
        } catch (Exception exception) {
            throw new IllegalStateException("Failed to decode operational reference string list", exception);
        }
    }

    public String writeComposition(List<ExecutionPlanPayload.CameraEnvironmentProfile> composition) {
        return write(composition == null ? List.of() : composition);
    }

    public List<ExecutionPlanPayload.CameraEnvironmentProfile> readComposition(String raw) {
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(raw, COMPOSITION_LIST);
        } catch (Exception exception) {
            throw new IllegalStateException("Failed to decode operational reference composition", exception);
        }
    }

    private String write(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception exception) {
            throw new IllegalStateException("Failed to encode operational reference payload", exception);
        }
    }
}
