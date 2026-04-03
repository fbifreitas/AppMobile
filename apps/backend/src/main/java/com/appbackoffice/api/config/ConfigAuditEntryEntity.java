package com.appbackoffice.api.config;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "config_audit_entries")
public class ConfigAuditEntryEntity {

    @Id
    private String id;

    @Column(nullable = false)
    private String packageId;

    @Column(nullable = false)
    private String actorId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ActorRole actorRole;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ConfigAuditAction action;

    @Column(nullable = false)
    private String tenantId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ConfigScope scope;

    @Column(nullable = false)
    private Instant createdAt;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getPackageId() {
        return packageId;
    }

    public void setPackageId(String packageId) {
        this.packageId = packageId;
    }

    public String getActorId() {
        return actorId;
    }

    public void setActorId(String actorId) {
        this.actorId = actorId;
    }

    public ActorRole getActorRole() {
        return actorRole;
    }

    public void setActorRole(ActorRole actorRole) {
        this.actorRole = actorRole;
    }

    public ConfigAuditAction getAction() {
        return action;
    }

    public void setAction(ConfigAuditAction action) {
        this.action = action;
    }

    public String getTenantId() {
        return tenantId;
    }

    public void setTenantId(String tenantId) {
        this.tenantId = tenantId;
    }

    public ConfigScope getScope() {
        return scope;
    }

    public void setScope(ConfigScope scope) {
        this.scope = scope;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}