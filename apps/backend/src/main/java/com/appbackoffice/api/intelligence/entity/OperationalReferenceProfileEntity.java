package com.appbackoffice.api.intelligence.entity;

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
@Table(name = "operational_reference_profiles")
public class OperationalReferenceProfileEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id")
    private String tenantId;

    @Enumerated(EnumType.STRING)
    @Column(name = "scope_type", nullable = false)
    private OperationalReferenceScope scopeType;

    @Enumerated(EnumType.STRING)
    @Column(name = "source_type", nullable = false)
    private OperationalReferenceSourceType sourceType;

    @Column(name = "active_flag", nullable = false)
    private boolean activeFlag = true;

    @Column(name = "asset_type", nullable = false)
    private String assetType;

    @Column(name = "asset_subtype", nullable = false)
    private String assetSubtype;

    @Column(name = "refined_asset_subtype")
    private String refinedAssetSubtype;

    @Column(name = "property_standard")
    private String propertyStandard;

    @Column(name = "region_state")
    private String regionState;

    @Column(name = "region_city")
    private String regionCity;

    @Column(name = "region_district")
    private String regionDistrict;

    @Column(name = "priority_weight", nullable = false)
    private int priorityWeight = 100;

    @Column(name = "confidence_score")
    private Double confidenceScore;

    @Column(name = "feedback_count", nullable = false)
    private int feedbackCount;

    @Column(name = "candidate_subtypes_json", columnDefinition = "TEXT")
    private String candidateSubtypesJson;

    @Column(name = "photo_locations_json", columnDefinition = "TEXT")
    private String photoLocationsJson;

    @Column(name = "composition_json", columnDefinition = "TEXT", nullable = false)
    private String compositionJson;

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

    public OperationalReferenceScope getScopeType() {
        return scopeType;
    }

    public void setScopeType(OperationalReferenceScope scopeType) {
        this.scopeType = scopeType;
    }

    public OperationalReferenceSourceType getSourceType() {
        return sourceType;
    }

    public void setSourceType(OperationalReferenceSourceType sourceType) {
        this.sourceType = sourceType;
    }

    public boolean isActiveFlag() {
        return activeFlag;
    }

    public void setActiveFlag(boolean activeFlag) {
        this.activeFlag = activeFlag;
    }

    public String getAssetType() {
        return assetType;
    }

    public void setAssetType(String assetType) {
        this.assetType = assetType;
    }

    public String getAssetSubtype() {
        return assetSubtype;
    }

    public void setAssetSubtype(String assetSubtype) {
        this.assetSubtype = assetSubtype;
    }

    public String getRefinedAssetSubtype() {
        return refinedAssetSubtype;
    }

    public void setRefinedAssetSubtype(String refinedAssetSubtype) {
        this.refinedAssetSubtype = refinedAssetSubtype;
    }

    public String getPropertyStandard() {
        return propertyStandard;
    }

    public void setPropertyStandard(String propertyStandard) {
        this.propertyStandard = propertyStandard;
    }

    public String getRegionState() {
        return regionState;
    }

    public void setRegionState(String regionState) {
        this.regionState = regionState;
    }

    public String getRegionCity() {
        return regionCity;
    }

    public void setRegionCity(String regionCity) {
        this.regionCity = regionCity;
    }

    public String getRegionDistrict() {
        return regionDistrict;
    }

    public void setRegionDistrict(String regionDistrict) {
        this.regionDistrict = regionDistrict;
    }

    public int getPriorityWeight() {
        return priorityWeight;
    }

    public void setPriorityWeight(int priorityWeight) {
        this.priorityWeight = priorityWeight;
    }

    public Double getConfidenceScore() {
        return confidenceScore;
    }

    public void setConfidenceScore(Double confidenceScore) {
        this.confidenceScore = confidenceScore;
    }

    public int getFeedbackCount() {
        return feedbackCount;
    }

    public void setFeedbackCount(int feedbackCount) {
        this.feedbackCount = feedbackCount;
    }

    public String getCandidateSubtypesJson() {
        return candidateSubtypesJson;
    }

    public void setCandidateSubtypesJson(String candidateSubtypesJson) {
        this.candidateSubtypesJson = candidateSubtypesJson;
    }

    public String getPhotoLocationsJson() {
        return photoLocationsJson;
    }

    public void setPhotoLocationsJson(String photoLocationsJson) {
        this.photoLocationsJson = photoLocationsJson;
    }

    public String getCompositionJson() {
        return compositionJson;
    }

    public void setCompositionJson(String compositionJson) {
        this.compositionJson = compositionJson;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
