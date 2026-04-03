package com.appbackoffice.api.job.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "jobs")
public class Job {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "case_id", nullable = false)
    private Long caseId;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "org_unit_id")
    private Long orgUnitId;

    @Column(nullable = false)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private JobStatus status;

    @Column(name = "assigned_to")
    private Long assignedTo;

    @Column(name = "deadline_at")
    private Instant deadlineAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public Job() {
    }

    public Job(Long caseId, String tenantId, String title, Instant deadlineAt) {
        this.caseId = caseId;
        this.tenantId = tenantId;
        this.title = title;
        this.deadlineAt = deadlineAt;
        this.status = JobStatus.ELIGIBLE_FOR_DISPATCH;
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() { return id; }
    public Long getCaseId() { return caseId; }
    public String getTenantId() { return tenantId; }
    public Long getOrgUnitId() { return orgUnitId; }
    public String getTitle() { return title; }
    public JobStatus getStatus() { return status; }
    public Long getAssignedTo() { return assignedTo; }
    public Instant getDeadlineAt() { return deadlineAt; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    public void setStatus(JobStatus status) { this.status = status; }
    public void setAssignedTo(Long assignedTo) { this.assignedTo = assignedTo; }
    public void setOrgUnitId(Long orgUnitId) { this.orgUnitId = orgUnitId; }
}
