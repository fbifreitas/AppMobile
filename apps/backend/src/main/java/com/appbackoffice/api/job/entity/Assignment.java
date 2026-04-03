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
@Table(name = "assignments")
public class Assignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "job_id", nullable = false)
    private Long jobId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "offered_at", nullable = false)
    private Instant offeredAt;

    @Column(name = "responded_at")
    private Instant respondedAt;

    @Enumerated(EnumType.STRING)
    @Column
    private AssignmentResponse response;

    public Assignment() {
    }

    public Assignment(Long jobId, Long userId, String tenantId) {
        this.jobId = jobId;
        this.userId = userId;
        this.tenantId = tenantId;
    }

    @PrePersist
    void onCreate() {
        if (offeredAt == null) offeredAt = Instant.now();
    }

    public Long getId() { return id; }
    public Long getJobId() { return jobId; }
    public Long getUserId() { return userId; }
    public String getTenantId() { return tenantId; }
    public Instant getOfferedAt() { return offeredAt; }
    public Instant getRespondedAt() { return respondedAt; }
    public AssignmentResponse getResponse() { return response; }

    public void respond(AssignmentResponse response) {
        this.response = response;
        this.respondedAt = Instant.now();
    }
}
