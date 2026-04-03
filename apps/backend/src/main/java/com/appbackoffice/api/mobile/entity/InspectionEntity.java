package com.appbackoffice.api.mobile.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "inspections")
public class InspectionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "submission_id")
    private Long submissionId;

    @Column(name = "job_id", nullable = false)
    private Long jobId;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "vistoriador_id", nullable = false)
    private Long vistoriadorId;

    @Column(name = "idempotency_key", nullable = false)
    private String idempotencyKey;

    @Column(name = "protocol_id", nullable = false)
    private String protocolId;

    @Column(nullable = false)
    private String status;

    @Column(name = "payload_json", nullable = false, columnDefinition = "CLOB")
    private String payloadJson;

    @Column(name = "submitted_at", nullable = false)
    private Instant submittedAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        if (submittedAt == null) {
            submittedAt = now;
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

    public Long getSubmissionId() {
        return submissionId;
    }

    public Long getJobId() {
        return jobId;
    }

    public String getTenantId() {
        return tenantId;
    }

    public Long getVistoriadorId() {
        return vistoriadorId;
    }

    public String getIdempotencyKey() {
        return idempotencyKey;
    }

    public String getProtocolId() {
        return protocolId;
    }

    public String getStatus() {
        return status;
    }

    public String getPayloadJson() {
        return payloadJson;
    }

    public Instant getSubmittedAt() {
        return submittedAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setSubmissionId(Long submissionId) {
        this.submissionId = submissionId;
    }

    public void setJobId(Long jobId) {
        this.jobId = jobId;
    }

    public void setTenantId(String tenantId) {
        this.tenantId = tenantId;
    }

    public void setVistoriadorId(Long vistoriadorId) {
        this.vistoriadorId = vistoriadorId;
    }

    public void setIdempotencyKey(String idempotencyKey) {
        this.idempotencyKey = idempotencyKey;
    }

    public void setProtocolId(String protocolId) {
        this.protocolId = protocolId;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public void setPayloadJson(String payloadJson) {
        this.payloadJson = payloadJson;
    }

    public void setSubmittedAt(Instant submittedAt) {
        this.submittedAt = submittedAt;
    }
}
