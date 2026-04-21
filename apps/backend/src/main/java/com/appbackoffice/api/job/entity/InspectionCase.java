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
@Table(name = "inspection_cases")
public class InspectionCase {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "demand_id")
    private Long demandId;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(nullable = false)
    private String number;

    @Column(name = "property_address", nullable = false)
    private String propertyAddress;

    @Column(name = "property_latitude")
    private Double propertyLatitude;

    @Column(name = "property_longitude")
    private Double propertyLongitude;

    @Column(name = "inspection_type", nullable = false)
    private String inspectionType;

    @Column
    private Instant deadline;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CaseStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public InspectionCase() {
    }

    public InspectionCase(String tenantId, String number, String propertyAddress,
                          Double propertyLatitude, Double propertyLongitude,
                          String inspectionType, Instant deadline) {
        this.tenantId = tenantId;
        this.number = number;
        this.propertyAddress = propertyAddress;
        this.propertyLatitude = propertyLatitude;
        this.propertyLongitude = propertyLongitude;
        this.inspectionType = inspectionType;
        this.deadline = deadline;
        this.status = CaseStatus.OPEN;
    }

    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    public Long getId() { return id; }
    public Long getDemandId() { return demandId; }
    public String getTenantId() { return tenantId; }
    public String getNumber() { return number; }
    public String getPropertyAddress() { return propertyAddress; }
    public Double getPropertyLatitude() { return propertyLatitude; }
    public Double getPropertyLongitude() { return propertyLongitude; }
    public String getInspectionType() { return inspectionType; }
    public Instant getDeadline() { return deadline; }
    public CaseStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }

    public void setDemandId(Long demandId) { this.demandId = demandId; }
    public void setStatus(CaseStatus status) { this.status = status; }
    public void setPropertyLatitude(Double propertyLatitude) { this.propertyLatitude = propertyLatitude; }
    public void setPropertyLongitude(Double propertyLongitude) { this.propertyLongitude = propertyLongitude; }
}
