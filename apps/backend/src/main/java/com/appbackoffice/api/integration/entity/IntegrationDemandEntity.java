package com.appbackoffice.api.integration.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "integration_demands")
public class IntegrationDemandEntity {

    @Id
    @Column(length = 64)
    private String id;

    @Column(name = "external_id", nullable = false, unique = true, length = 128)
    private String externalId;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "requested_by", nullable = false, length = 120)
    private String requestedBy;

    @Column(name = "inspection_type", nullable = false, length = 40)
    private String inspectionType;

    @Column(name = "requested_deadline", nullable = false)
    private Instant requestedDeadline;

    @Column(name = "property_address_json", nullable = false, columnDefinition = "CLOB")
    private String propertyAddressJson;

    @Column(name = "client_data_json", columnDefinition = "CLOB")
    private String clientDataJson;

    @Column(name = "normalized_payload", nullable = false, columnDefinition = "CLOB")
    private String normalizedPayload;

    @Column(nullable = false, length = 40)
    private String status;

    @Column(name = "case_id")
    private Long caseId;

    @Column(name = "job_id")
    private Long jobId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        if (id == null) {
            id = UUID.randomUUID().toString();
        }
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

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getExternalId() {
        return externalId;
    }

    public void setExternalId(String externalId) {
        this.externalId = externalId;
    }

    public String getTenantId() {
        return tenantId;
    }

    public void setTenantId(String tenantId) {
        this.tenantId = tenantId;
    }

    public String getRequestedBy() {
        return requestedBy;
    }

    public void setRequestedBy(String requestedBy) {
        this.requestedBy = requestedBy;
    }

    public String getInspectionType() {
        return inspectionType;
    }

    public void setInspectionType(String inspectionType) {
        this.inspectionType = inspectionType;
    }

    public Instant getRequestedDeadline() {
        return requestedDeadline;
    }

    public void setRequestedDeadline(Instant requestedDeadline) {
        this.requestedDeadline = requestedDeadline;
    }

    public String getPropertyAddressJson() {
        return propertyAddressJson;
    }

    public void setPropertyAddressJson(String propertyAddressJson) {
        this.propertyAddressJson = propertyAddressJson;
    }

    public String getClientDataJson() {
        return clientDataJson;
    }

    public void setClientDataJson(String clientDataJson) {
        this.clientDataJson = clientDataJson;
    }

    public String getNormalizedPayload() {
        return normalizedPayload;
    }

    public void setNormalizedPayload(String normalizedPayload) {
        this.normalizedPayload = normalizedPayload;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Long getCaseId() {
        return caseId;
    }

    public void setCaseId(Long caseId) {
        this.caseId = caseId;
    }

    public Long getJobId() {
        return jobId;
    }

    public void setJobId(Long jobId) {
        this.jobId = jobId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
