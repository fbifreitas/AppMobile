package com.appbackoffice.api.platform.entity;

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
@Table(name = "tenant_licenses")
public class TenantLicenseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false, unique = true)
    private String tenantId;

    @Enumerated(EnumType.STRING)
    @Column(name = "license_model", nullable = false)
    private LicenseModel licenseModel;

    @Column(name = "contracted_seats", nullable = false)
    private Integer contractedSeats;

    @Column(name = "warning_seats", nullable = false)
    private Integer warningSeats;

    @Column(name = "hard_limit_enforced", nullable = false)
    private boolean hardLimitEnforced;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

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

    public LicenseModel getLicenseModel() {
        return licenseModel;
    }

    public void setLicenseModel(LicenseModel licenseModel) {
        this.licenseModel = licenseModel;
    }

    public Integer getContractedSeats() {
        return contractedSeats;
    }

    public void setContractedSeats(Integer contractedSeats) {
        this.contractedSeats = contractedSeats;
    }

    public Integer getWarningSeats() {
        return warningSeats;
    }

    public void setWarningSeats(Integer warningSeats) {
        this.warningSeats = warningSeats;
    }

    public boolean isHardLimitEnforced() {
        return hardLimitEnforced;
    }

    public void setHardLimitEnforced(boolean hardLimitEnforced) {
        this.hardLimitEnforced = hardLimitEnforced;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
