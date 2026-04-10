package com.appbackoffice.api.user.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "users", uniqueConstraints = {
        @UniqueConstraint(name = "uk_users_tenant_email", columnNames = {"tenant_id", "email"})
})
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(nullable = false)
    private String email;

    @Column(nullable = false)
    private String nome;

    @Column(nullable = false)
    private String tipo; // CLT, PJ

    @Column(name = "cpf")
    private String cpf;

    @Column(name = "cnpj")
    private String cnpj;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "phone")
    private String phone;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserSource source;

    @Transient
    private UserRole role;

    @Column(name = "external_id")
    private String externalId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "approved_at")
    private Instant approvedAt;

    @Column(name = "rejected_at")
    private Instant rejectedAt;

    @Column(name = "rejection_reason")
    private String rejectionReason;

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private UserLifecycle lifecycle;

    public User() {
    }

    // móbile onboarding: cria pendente
    public User(String tenantId, String email, String nome, String tipo) {
        this.tenantId = tenantId;
        this.email = email;
        this.nome = nome;
        this.tipo = tipo;
        this.status = UserStatus.AWAITING_APPROVAL;
        this.source = UserSource.MOBILE_ONBOARDING;
        this.role = UserRole.FIELD_AGENT;
        this.createdAt = Instant.now();
    }

    // web/AD: cria já aprovado com role explícito
    public User(String tenantId, String email, String nome, String tipo, UserRole role, UserSource source) {
        this.tenantId = tenantId;
        this.email = email;
        this.nome = nome;
        this.tipo = tipo;
        this.role = role;
        this.source = source;
        this.status = UserStatus.APPROVED;
        this.approvedAt = Instant.now();
        this.createdAt = Instant.now();
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTenantId() {
        return tenantId;
    }

    public void setTenantId(String tenantId) {
        this.tenantId = tenantId;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getTipo() {
        return tipo;
    }

    public void setTipo(String tipo) {
        this.tipo = tipo;
    }

    public String getCpf() {
        return cpf;
    }

    public void setCpf(String cpf) {
        this.cpf = cpf;
    }

    public String getCnpj() {
        return cnpj;
    }

    public void setCnpj(String cnpj) {
        this.cnpj = cnpj;
    }

    public LocalDate getBirthDate() {
        return birthDate;
    }

    public void setBirthDate(LocalDate birthDate) {
        this.birthDate = birthDate;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public UserStatus getStatus() {
        return status;
    }

    public void setStatus(UserStatus status) {
        this.status = status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getApprovedAt() {
        return approvedAt;
    }

    public void setApprovedAt(Instant approvedAt) {
        this.approvedAt = approvedAt;
    }

    public Instant getRejectedAt() {
        return rejectedAt;
    }

    public void setRejectedAt(Instant rejectedAt) {
        this.rejectedAt = rejectedAt;
    }

    public String getRejectionReason() {
        return rejectionReason;
    }

    public void setRejectionReason(String rejectionReason) {
        this.rejectionReason = rejectionReason;
    }

    public UserSource getSource() {
        return source;
    }

    public void setSource(UserSource source) {
        this.source = source;
    }

    public UserRole getRole() {
        return role;
    }

    public void setRole(UserRole role) {
        this.role = role;
    }

    public String getExternalId() {
        return externalId;
    }

    public void setExternalId(String externalId) {
        this.externalId = externalId;
    }

    public UserLifecycle getLifecycle() {
        return lifecycle;
    }

    public void setLifecycle(UserLifecycle lifecycle) {
        this.lifecycle = lifecycle;
        if (lifecycle != null && lifecycle.getUser() != this) {
            lifecycle.setUser(this);
        }
    }
}
