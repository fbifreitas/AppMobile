CREATE TABLE tenant_applications (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(120) NOT NULL UNIQUE REFERENCES tenants(id),
    app_code VARCHAR(80) NOT NULL,
    brand_name VARCHAR(160) NOT NULL,
    display_name VARCHAR(160) NOT NULL,
    application_id VARCHAR(160) NOT NULL,
    bundle_id VARCHAR(160) NOT NULL,
    firebase_app_id VARCHAR(200),
    distribution_channel VARCHAR(80),
    distribution_group VARCHAR(120),
    status VARCHAR(32) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tenant_applications_app_code
    ON tenant_applications (app_code);

CREATE TABLE tenant_licenses (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(120) NOT NULL UNIQUE REFERENCES tenants(id),
    license_model VARCHAR(40) NOT NULL,
    contracted_seats INTEGER NOT NULL DEFAULT 0,
    warning_seats INTEGER NOT NULL DEFAULT 0,
    hard_limit_enforced BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
