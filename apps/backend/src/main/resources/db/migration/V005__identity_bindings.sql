-- V005: Vinculo entre user canônico e provider de identidade (BOW-103)
CREATE TABLE identity_bindings (
    id            VARCHAR(64)  NOT NULL,
    user_id       BIGINT       NOT NULL,
    provider_type VARCHAR(50)  NOT NULL,
    provider_sub  VARCHAR(255) NOT NULL,
    tenant_id     VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP    NOT NULL,
    CONSTRAINT pk_identity_bindings PRIMARY KEY (id),
    CONSTRAINT uq_identity_bindings_provider UNIQUE (provider_type, provider_sub, tenant_id),
    CONSTRAINT fk_identity_bindings_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_identity_bindings_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);
