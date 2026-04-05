package com.appbackoffice.api.config;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "config_packages")
public class ConfigPackageEntity {

    @Id
    private String id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ConfigScope scope;

    @Column(nullable = false)
    private String tenantId;

    private String unitId;
    private String roleId;
    private String userId;
    private String deviceId;

    @Column(nullable = false)
    private Instant updatedAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ConfigPackageStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RolloutActivation rolloutActivation;

    private Instant rolloutStartsAt;
    private Instant rolloutEndsAt;

    @Lob
    private String batchUserIdsCsv;

    private Boolean requireBiometric;
    private Integer cameraMinPhotos;
    private Integer cameraMaxPhotos;
    private Boolean enableVoiceCommands;
    private String theme;
    private String appUpdateChannel;

    @Lob
    @Column(columnDefinition = "CLOB")
    private String checkinSectionsJson;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public ConfigScope getScope() {
        return scope;
    }

    public void setScope(ConfigScope scope) {
        this.scope = scope;
    }

    public String getTenantId() {
        return tenantId;
    }

    public void setTenantId(String tenantId) {
        this.tenantId = tenantId;
    }

    public String getUnitId() {
        return unitId;
    }

    public void setUnitId(String unitId) {
        this.unitId = unitId;
    }

    public String getRoleId() {
        return roleId;
    }

    public void setRoleId(String roleId) {
        this.roleId = roleId;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }

    public ConfigPackageStatus getStatus() {
        return status;
    }

    public void setStatus(ConfigPackageStatus status) {
        this.status = status;
    }

    public RolloutActivation getRolloutActivation() {
        return rolloutActivation;
    }

    public void setRolloutActivation(RolloutActivation rolloutActivation) {
        this.rolloutActivation = rolloutActivation;
    }

    public Instant getRolloutStartsAt() {
        return rolloutStartsAt;
    }

    public void setRolloutStartsAt(Instant rolloutStartsAt) {
        this.rolloutStartsAt = rolloutStartsAt;
    }

    public Instant getRolloutEndsAt() {
        return rolloutEndsAt;
    }

    public void setRolloutEndsAt(Instant rolloutEndsAt) {
        this.rolloutEndsAt = rolloutEndsAt;
    }

    public String getBatchUserIdsCsv() {
        return batchUserIdsCsv;
    }

    public void setBatchUserIdsCsv(String batchUserIdsCsv) {
        this.batchUserIdsCsv = batchUserIdsCsv;
    }

    public Boolean getRequireBiometric() {
        return requireBiometric;
    }

    public void setRequireBiometric(Boolean requireBiometric) {
        this.requireBiometric = requireBiometric;
    }

    public Integer getCameraMinPhotos() {
        return cameraMinPhotos;
    }

    public void setCameraMinPhotos(Integer cameraMinPhotos) {
        this.cameraMinPhotos = cameraMinPhotos;
    }

    public Integer getCameraMaxPhotos() {
        return cameraMaxPhotos;
    }

    public void setCameraMaxPhotos(Integer cameraMaxPhotos) {
        this.cameraMaxPhotos = cameraMaxPhotos;
    }

    public Boolean getEnableVoiceCommands() {
        return enableVoiceCommands;
    }

    public void setEnableVoiceCommands(Boolean enableVoiceCommands) {
        this.enableVoiceCommands = enableVoiceCommands;
    }

    public String getTheme() {
        return theme;
    }

    public void setTheme(String theme) {
        this.theme = theme;
    }

    public String getAppUpdateChannel() {
        return appUpdateChannel;
    }

    public void setAppUpdateChannel(String appUpdateChannel) {
        this.appUpdateChannel = appUpdateChannel;
    }

    public String getCheckinSectionsJson() {
        return checkinSectionsJson;
    }

    public void setCheckinSectionsJson(String checkinSectionsJson) {
        this.checkinSectionsJson = checkinSectionsJson;
    }
}
