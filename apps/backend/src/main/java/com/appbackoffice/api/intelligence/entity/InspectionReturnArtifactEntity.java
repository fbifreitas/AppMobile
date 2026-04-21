package com.appbackoffice.api.intelligence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "inspection_return_artifacts")
public class InspectionReturnArtifactEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "inspection_id", nullable = false)
    private Long inspectionId;

    @Column(name = "submission_id")
    private Long submissionId;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "case_id", nullable = false)
    private Long caseId;

    @Column(name = "job_id", nullable = false)
    private Long jobId;

    @Column(name = "execution_plan_snapshot_id")
    private Long executionPlanSnapshotId;

    @Column(name = "raw_storage_key", nullable = false)
    private String rawStorageKey;

    @Column(name = "normalized_storage_key", nullable = false)
    private String normalizedStorageKey;

    @Lob
    @Column(name = "summary_json", nullable = false)
    private String summaryJson;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    public Long getId() {
        return id;
    }

    public Long getInspectionId() {
        return inspectionId;
    }

    public void setInspectionId(Long inspectionId) {
        this.inspectionId = inspectionId;
    }

    public Long getSubmissionId() {
        return submissionId;
    }

    public void setSubmissionId(Long submissionId) {
        this.submissionId = submissionId;
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

    public Long getJobId() {
        return jobId;
    }

    public void setJobId(Long jobId) {
        this.jobId = jobId;
    }

    public Long getExecutionPlanSnapshotId() {
        return executionPlanSnapshotId;
    }

    public void setExecutionPlanSnapshotId(Long executionPlanSnapshotId) {
        this.executionPlanSnapshotId = executionPlanSnapshotId;
    }

    public String getRawStorageKey() {
        return rawStorageKey;
    }

    public void setRawStorageKey(String rawStorageKey) {
        this.rawStorageKey = rawStorageKey;
    }

    public String getNormalizedStorageKey() {
        return normalizedStorageKey;
    }

    public void setNormalizedStorageKey(String normalizedStorageKey) {
        this.normalizedStorageKey = normalizedStorageKey;
    }

    public String getSummaryJson() {
        return summaryJson;
    }

    public void setSummaryJson(String summaryJson) {
        this.summaryJson = summaryJson;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
