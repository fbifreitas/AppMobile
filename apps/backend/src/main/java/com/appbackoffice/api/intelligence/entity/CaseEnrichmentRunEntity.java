package com.appbackoffice.api.intelligence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "case_enrichment_runs")
public class CaseEnrichmentRunEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "case_id", nullable = false)
    private Long caseId;

    @Column(name = "provider_name", nullable = false)
    private String providerName;

    @Column(name = "model_name")
    private String modelName;

    @Column(name = "prompt_version")
    private String promptVersion;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EnrichmentRunStatus status;

    @Column(name = "request_storage_key")
    private String requestStorageKey;

    @Column(name = "response_raw_storage_key")
    private String responseRawStorageKey;

    @Column(name = "response_normalized_storage_key")
    private String responseNormalizedStorageKey;

    @Lob
    @Column(name = "facts_json")
    private String factsJson;

    @Lob
    @Column(name = "quality_flags_json")
    private String qualityFlagsJson;

    @Column(name = "confidence_score")
    private Double confidenceScore;

    @Column(name = "error_code")
    private String errorCode;

    @Lob
    @Column(name = "error_message")
    private String errorMessage;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        if (updatedAt == null) {
            updatedAt = now;
        }
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public String getTenantId() {
        return tenantId;
    }

    public void setTenantId(String tenantId) {
        this.tenantId = tenantId;
    }

    public Long getCaseId() {
        return caseId;
    }

    public void setCaseId(Long caseId) {
        this.caseId = caseId;
    }

    public String getProviderName() {
        return providerName;
    }

    public void setProviderName(String providerName) {
        this.providerName = providerName;
    }

    public String getModelName() {
        return modelName;
    }

    public void setModelName(String modelName) {
        this.modelName = modelName;
    }

    public String getPromptVersion() {
        return promptVersion;
    }

    public void setPromptVersion(String promptVersion) {
        this.promptVersion = promptVersion;
    }

    public EnrichmentRunStatus getStatus() {
        return status;
    }

    public void setStatus(EnrichmentRunStatus status) {
        this.status = status;
    }

    public String getRequestStorageKey() {
        return requestStorageKey;
    }

    public void setRequestStorageKey(String requestStorageKey) {
        this.requestStorageKey = requestStorageKey;
    }

    public String getResponseRawStorageKey() {
        return responseRawStorageKey;
    }

    public void setResponseRawStorageKey(String responseRawStorageKey) {
        this.responseRawStorageKey = responseRawStorageKey;
    }

    public String getResponseNormalizedStorageKey() {
        return responseNormalizedStorageKey;
    }

    public void setResponseNormalizedStorageKey(String responseNormalizedStorageKey) {
        this.responseNormalizedStorageKey = responseNormalizedStorageKey;
    }

    public String getFactsJson() {
        return factsJson;
    }

    public void setFactsJson(String factsJson) {
        this.factsJson = factsJson;
    }

    public String getQualityFlagsJson() {
        return qualityFlagsJson;
    }

    public void setQualityFlagsJson(String qualityFlagsJson) {
        this.qualityFlagsJson = qualityFlagsJson;
    }

    public Double getConfidenceScore() {
        return confidenceScore;
    }

    public void setConfidenceScore(Double confidenceScore) {
        this.confidenceScore = confidenceScore;
    }

    public String getErrorCode() {
        return errorCode;
    }

    public void setErrorCode(String errorCode) {
        this.errorCode = errorCode;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public Instant getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(Instant completedAt) {
        this.completedAt = completedAt;
    }
}
