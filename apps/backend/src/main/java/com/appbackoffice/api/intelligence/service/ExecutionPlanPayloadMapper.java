package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.model.ExecutionPlanPayload;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

@Service
public class ExecutionPlanPayloadMapper {

    private final ObjectMapper objectMapper;

    public ExecutionPlanPayloadMapper(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public String write(ExecutionPlanPayload payload) {
        try {
            return objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Unable to serialize execution plan payload", exception);
        }
    }

    public ExecutionPlanPayload read(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalStateException("Execution plan payload is empty");
        }
        try {
            return objectMapper.readValue(value, ExecutionPlanPayload.class);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Unable to deserialize execution plan payload", exception);
        }
    }
}
