package com.appbackoffice.api.valuation.entity;

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
@Table(name = "intake_validations")
public class IntakeValidationEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "valuation_process_id", nullable = false)
    private Long valuationProcessId;

    @Column(name = "validated_by")
    private Long validatedBy;

    @Column(name = "issues_json", columnDefinition = "CLOB")
    private String issuesJson;

    @Column(name = "notes", columnDefinition = "CLOB")
    private String notes;

    @Column(name = "validated_at", nullable = false)
    private Instant validatedAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private IntakeValidationResult result;

    @PrePersist
    void onCreate() {
        if (validatedAt == null) {
            validatedAt = Instant.now();
        }
    }

    public Long getId() {
        return id;
    }

    public Long getValuationProcessId() {
        return valuationProcessId;
    }

    public void setValuationProcessId(Long valuationProcessId) {
        this.valuationProcessId = valuationProcessId;
    }

    public Long getValidatedBy() {
        return validatedBy;
    }

    public void setValidatedBy(Long validatedBy) {
        this.validatedBy = validatedBy;
    }

    public String getIssuesJson() {
        return issuesJson;
    }

    public void setIssuesJson(String issuesJson) {
        this.issuesJson = issuesJson;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public Instant getValidatedAt() {
        return validatedAt;
    }

    public IntakeValidationResult getResult() {
        return result;
    }

    public void setResult(IntakeValidationResult result) {
        this.result = result;
    }
}
