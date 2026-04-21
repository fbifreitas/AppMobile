package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.dto.EnrichmentRunResponse;
import com.appbackoffice.api.intelligence.entity.CaseEnrichmentRunEntity;
import com.appbackoffice.api.intelligence.entity.EnrichmentRunStatus;
import com.appbackoffice.api.intelligence.repository.CaseEnrichmentRunRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

@Service
public class EnrichmentRunResponseFactory {

    private final ObjectMapper objectMapper;
    private final CaseEnrichmentRunRepository runRepository;

    public EnrichmentRunResponseFactory(ObjectMapper objectMapper,
                                        CaseEnrichmentRunRepository runRepository) {
        this.objectMapper = objectMapper;
        this.runRepository = runRepository;
    }

    public EnrichmentRunResponse create(CaseEnrichmentRunEntity run) {
        return new EnrichmentRunResponse(
                run.getId(),
                run.getCaseId(),
                run.getStatus(),
                run.getStatus() == EnrichmentRunStatus.TEMPORARILY_UNAVAILABLE,
                runRepository.countByTenantIdAndCaseId(run.getTenantId(), run.getCaseId()),
                run.getProviderName(),
                run.getModelName(),
                run.getConfidenceScore() == null ? 0.0 : run.getConfidenceScore(),
                run.getCreatedAt(),
                run.getCompletedAt(),
                parseJson(run.getFactsJson()),
                parseJson(run.getQualityFlagsJson()),
                run.getRequestStorageKey(),
                run.getResponseRawStorageKey(),
                run.getResponseNormalizedStorageKey(),
                run.getErrorCode(),
                run.getErrorMessage()
        );
    }

    private JsonNode parseJson(String value) {
        if (value == null || value.isBlank()) {
            return objectMapper.createArrayNode();
        }
        try {
            return objectMapper.readTree(value);
        } catch (JsonProcessingException exception) {
            return objectMapper.createArrayNode();
        }
    }
}
