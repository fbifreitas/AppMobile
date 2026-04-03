package com.appbackoffice.api.job.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "demands")
public class Demand {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id", nullable = false)
    private String externalId;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(nullable = false)
    private String source;

    @Column(name = "normalized_payload", nullable = false, columnDefinition = "TEXT")
    private String normalizedPayload;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DemandStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public Demand() {
    }

    public Demand(String externalId, String tenantId, String source, String normalizedPayload) {
        this.externalId = externalId;
        this.tenantId = tenantId;
        this.source = source;
        this.normalizedPayload = normalizedPayload;
        this.status = DemandStatus.RECEIVED;
    }

    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    public Long getId() { return id; }
    public String getExternalId() { return externalId; }
    public String getTenantId() { return tenantId; }
    public String getSource() { return source; }
    public String getNormalizedPayload() { return normalizedPayload; }
    public DemandStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }

    public void setStatus(DemandStatus status) { this.status = status; }
}
