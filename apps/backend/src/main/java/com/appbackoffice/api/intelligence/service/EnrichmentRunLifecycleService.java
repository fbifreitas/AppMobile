package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.entity.CaseEnrichmentRunEntity;
import com.appbackoffice.api.intelligence.entity.EnrichmentRunStatus;
import com.appbackoffice.api.intelligence.port.ResearchProviderResponse;
import com.appbackoffice.api.intelligence.repository.CaseEnrichmentRunRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
public class EnrichmentRunLifecycleService {

    private final CaseEnrichmentRunRepository runRepository;
    private final ObjectMapper objectMapper;

    public EnrichmentRunLifecycleService(CaseEnrichmentRunRepository runRepository,
                                         ObjectMapper objectMapper) {
        this.runRepository = runRepository;
        this.objectMapper = objectMapper;
    }

    public CaseEnrichmentRunEntity queue(String tenantId, Long caseId) {
        CaseEnrichmentRunEntity run = new CaseEnrichmentRunEntity();
        run.setTenantId(tenantId);
        run.setCaseId(caseId);
        run.setProviderName("PENDING");
        run.setPromptVersion("v1");
        run.setStatus(EnrichmentRunStatus.QUEUED);
        return runRepository.save(run);
    }

    public CaseEnrichmentRunEntity markRequestStored(CaseEnrichmentRunEntity run, String requestStorageKey) {
        run.setRequestStorageKey(requestStorageKey);
        return runRepository.save(run);
    }

    public CaseEnrichmentRunEntity complete(CaseEnrichmentRunEntity run,
                                            ResearchProviderResponse providerResponse,
                                            EnrichmentArtifactStorageService.StoredResponseArtifacts artifacts) {
        run.setProviderName(providerResponse.providerName());
        run.setModelName(providerResponse.modelName());
        run.setPromptVersion(providerResponse.promptVersion());
        run.setFactsJson(writeJson(providerResponse.normalizedPayload().path("facts")));
        run.setQualityFlagsJson(writeJson(objectMapper.valueToTree(providerResponse.qualityFlags())));
        run.setConfidenceScore(providerResponse.confidenceScore());
        run.setResponseRawStorageKey(artifacts.rawStorageKey());
        run.setResponseNormalizedStorageKey(artifacts.normalizedStorageKey());
        run.setErrorCode(resolveErrorCode(providerResponse));
        run.setErrorMessage(resolveErrorMessage(providerResponse));
        run.setStatus(resolveStatus(providerResponse));
        run.setCompletedAt(Instant.now());
        return runRepository.save(run);
    }

    public void fail(CaseEnrichmentRunEntity run, RuntimeException exception) {
        String message = exception.getMessage() == null ? "Automatic analysis failed unexpectedly." : exception.getMessage();
        run.setStatus(EnrichmentRunStatus.FAILED);
        run.setErrorCode("ENRICHMENT_FAILED");
        run.setErrorMessage(message);
        run.setCompletedAt(Instant.now());
        runRepository.save(run);
    }

    public boolean isRetryable(CaseEnrichmentRunEntity run) {
        return run.getStatus() == EnrichmentRunStatus.TEMPORARILY_UNAVAILABLE;
    }

    private EnrichmentRunStatus resolveStatus(ResearchProviderResponse providerResponse) {
        if (containsAnyQualityFlag(providerResponse, "GEMINI_TEMPORARILY_UNAVAILABLE", "GEMINI_QUOTA_EXCEEDED")) {
            return EnrichmentRunStatus.TEMPORARILY_UNAVAILABLE;
        }
        return providerResponse.requiresManualReview() ? EnrichmentRunStatus.REVIEW_REQUIRED : EnrichmentRunStatus.COMPLETED;
    }

    private String resolveErrorCode(ResearchProviderResponse providerResponse) {
        if (containsAnyQualityFlag(providerResponse, "GEMINI_TEMPORARILY_UNAVAILABLE")) {
            return "ENRICHMENT_TEMPORARILY_UNAVAILABLE";
        }
        if (containsAnyQualityFlag(providerResponse, "GEMINI_QUOTA_EXCEEDED")) {
            return "ENRICHMENT_PROVIDER_QUOTA_EXCEEDED";
        }
        if (containsAnyQualityFlag(providerResponse, "GEMINI_GATEWAY_ERROR")) {
            return "ENRICHMENT_GATEWAY_ERROR";
        }
        return null;
    }

    private String resolveErrorMessage(ResearchProviderResponse providerResponse) {
        if (containsAnyQualityFlag(providerResponse, "GEMINI_TEMPORARILY_UNAVAILABLE")) {
            return "Automatic analysis is temporarily unavailable. Retry in a few minutes or continue with manual review.";
        }
        if (containsAnyQualityFlag(providerResponse, "GEMINI_QUOTA_EXCEEDED")) {
            return "Automatic analysis exceeded the provider quota for the current window. Retry later or continue with manual review.";
        }
        if (containsAnyQualityFlag(providerResponse, "GEMINI_GATEWAY_ERROR")) {
            return "Automatic analysis could not be completed because of an integration error. Retry or continue with manual review.";
        }
        return null;
    }

    private boolean containsAnyQualityFlag(ResearchProviderResponse providerResponse, String... candidates) {
        if (providerResponse.qualityFlags() == null || providerResponse.qualityFlags().isEmpty()) {
            return false;
        }
        for (String qualityFlag : providerResponse.qualityFlags()) {
            for (String candidate : candidates) {
                if (candidate.equalsIgnoreCase(qualityFlag)) {
                    return true;
                }
            }
        }
        return false;
    }

    private String writeJson(JsonNode node) {
        try {
            return objectMapper.writeValueAsString(node);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Unable to serialize JSON payload", exception);
        }
    }
}
