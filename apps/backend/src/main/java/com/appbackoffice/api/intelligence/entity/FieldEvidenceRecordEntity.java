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
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "field_evidence_records")
public class FieldEvidenceRecordEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "inspection_id", nullable = false)
    private Long inspectionId;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "case_id", nullable = false)
    private Long caseId;

    @Column(name = "job_id", nullable = false)
    private Long jobId;

    @Column(name = "source_section", nullable = false)
    private String sourceSection;

    @Column(name = "macro_location")
    private String macroLocation;

    @Column(name = "environment_name")
    private String environmentName;

    @Column(name = "element_name")
    private String elementName;

    @Column(name = "required_flag", nullable = false)
    private boolean requiredFlag;

    @Column(name = "min_photos")
    private Integer minPhotos;

    @Column(name = "captured_photos")
    private Integer capturedPhotos;

    @Enumerated(EnumType.STRING)
    @Column(name = "evidence_status", nullable = false)
    private FieldEvidenceStatus evidenceStatus;

    @Lob
    @Column(name = "evidence_json")
    private String evidenceJson;

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

    public String getSourceSection() {
        return sourceSection;
    }

    public void setSourceSection(String sourceSection) {
        this.sourceSection = sourceSection;
    }

    public String getMacroLocation() {
        return macroLocation;
    }

    public void setMacroLocation(String macroLocation) {
        this.macroLocation = macroLocation;
    }

    public String getEnvironmentName() {
        return environmentName;
    }

    public void setEnvironmentName(String environmentName) {
        this.environmentName = environmentName;
    }

    public String getElementName() {
        return elementName;
    }

    public void setElementName(String elementName) {
        this.elementName = elementName;
    }

    public boolean isRequiredFlag() {
        return requiredFlag;
    }

    public void setRequiredFlag(boolean requiredFlag) {
        this.requiredFlag = requiredFlag;
    }

    public Integer getMinPhotos() {
        return minPhotos;
    }

    public void setMinPhotos(Integer minPhotos) {
        this.minPhotos = minPhotos;
    }

    public Integer getCapturedPhotos() {
        return capturedPhotos;
    }

    public void setCapturedPhotos(Integer capturedPhotos) {
        this.capturedPhotos = capturedPhotos;
    }

    public FieldEvidenceStatus getEvidenceStatus() {
        return evidenceStatus;
    }

    public void setEvidenceStatus(FieldEvidenceStatus evidenceStatus) {
        this.evidenceStatus = evidenceStatus;
    }

    public String getEvidenceJson() {
        return evidenceJson;
    }

    public void setEvidenceJson(String evidenceJson) {
        this.evidenceJson = evidenceJson;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
