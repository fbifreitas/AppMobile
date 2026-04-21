package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.entity.CaseEnrichmentRunEntity;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.appbackoffice.api.job.entity.InspectionCase;
import com.appbackoffice.api.storage.StorageResult;
import com.appbackoffice.api.storage.StorageService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;

@Service
public class EnrichmentArtifactStorageService {

    private final StorageService storageService;
    private final ObjectMapper objectMapper;

    public EnrichmentArtifactStorageService(StorageService storageService,
                                           ObjectMapper objectMapper) {
        this.storageService = storageService;
        this.objectMapper = objectMapper;
    }

    public String storeRequestArtifact(InspectionCase inspectionCase, Long runId) {
        ObjectNode request = objectMapper.createObjectNode();
        request.put("tenantId", inspectionCase.getTenantId());
        request.put("caseId", inspectionCase.getId());
        request.put("caseNumber", inspectionCase.getNumber());
        request.put("propertyAddress", inspectionCase.getPropertyAddress());
        request.put("assetType", inspectionCase.getInspectionType());
        StorageResult result = storageService.store(
                buildStorageKey(inspectionCase.getId(), runId, "request.json"),
                writeJson(request).getBytes(StandardCharsets.UTF_8),
                "application/json"
        );
        return result.key();
    }

    public StoredResponseArtifacts storeResponseArtifacts(CaseEnrichmentRunEntity run,
                                                          ResearchProviderResponse providerResponse) {
        StorageResult raw = storageService.store(
                buildStorageKey(run.getCaseId(), run.getId(), "response_raw.json"),
                writeJson(providerResponse.rawPayload()).getBytes(StandardCharsets.UTF_8),
                "application/json"
        );
        StorageResult normalized = storageService.store(
                buildStorageKey(run.getCaseId(), run.getId(), "response_normalized.json"),
                writeJson(providerResponse.normalizedPayload()).getBytes(StandardCharsets.UTF_8),
                "application/json"
        );
        return new StoredResponseArtifacts(raw.key(), normalized.key());
    }

    private String buildStorageKey(Long caseId, Long runId, String fileName) {
        return "raw/cases/%s/research/run-%s/%s".formatted(caseId, runId, fileName);
    }

    private String writeJson(JsonNode node) {
        try {
            return objectMapper.writeValueAsString(node);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Unable to serialize JSON payload", exception);
        }
    }

    public record StoredResponseArtifacts(
            String rawStorageKey,
            String normalizedStorageKey
    ) {
    }
}
