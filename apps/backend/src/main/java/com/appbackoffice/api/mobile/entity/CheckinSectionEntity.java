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
@Table(name = "checkin_sections")
public class CheckinSectionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "tipo_imovel")
    private String tipoImovel;

    @Column(name = "section_key", nullable = false)
    private String sectionKey;

    @Column(name = "section_label", nullable = false)
    private String sectionLabel;

    @Column(nullable = false)
    private boolean mandatory;

    @Column(name = "photo_min", nullable = false)
    private Integer photoMin;

    @Column(name = "photo_max", nullable = false)
    private Integer photoMax;

    @Column(name = "desired_items_json", nullable = false, columnDefinition = "CLOB")
    private String desiredItemsJson;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;

    @Column(nullable = false)
    private boolean active;

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

    public String getTipoImovel() {
        return tipoImovel;
    }

    public String getSectionKey() {
        return sectionKey;
    }

    public String getSectionLabel() {
        return sectionLabel;
    }

    public boolean isMandatory() {
        return mandatory;
    }

    public Integer getPhotoMin() {
        return photoMin;
    }

    public Integer getPhotoMax() {
        return photoMax;
    }

    public String getDesiredItemsJson() {
        return desiredItemsJson;
    }

    public Integer getSortOrder() {
        return sortOrder;
    }

    public boolean isActive() {
        return active;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setTenantId(String tenantId) {
        this.tenantId = tenantId;
    }

    public void setTipoImovel(String tipoImovel) {
        this.tipoImovel = tipoImovel;
    }

    public void setSectionKey(String sectionKey) {
        this.sectionKey = sectionKey;
    }

    public void setSectionLabel(String sectionLabel) {
        this.sectionLabel = sectionLabel;
    }

    public void setMandatory(boolean mandatory) {
        this.mandatory = mandatory;
    }

    public void setPhotoMin(Integer photoMin) {
        this.photoMin = photoMin;
    }

    public void setPhotoMax(Integer photoMax) {
        this.photoMax = photoMax;
    }

    public void setDesiredItemsJson(String desiredItemsJson) {
        this.desiredItemsJson = desiredItemsJson;
    }

    public void setSortOrder(Integer sortOrder) {
        this.sortOrder = sortOrder;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
