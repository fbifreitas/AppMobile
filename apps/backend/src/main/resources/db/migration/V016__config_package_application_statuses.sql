CREATE TABLE config_package_application_statuses (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(80) NOT NULL,
    package_id VARCHAR(120),
    package_version VARCHAR(120) NOT NULL,
    actor_id VARCHAR(80) NOT NULL,
    device_id VARCHAR(120),
    app_version VARCHAR(80),
    platform VARCHAR(40),
    status VARCHAR(20) NOT NULL CHECK (status IN ('APPLIED', 'REJECTED')),
    message VARCHAR(500),
    applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_config_application_status_tenant_updated
    ON config_package_application_statuses (tenant_id, updated_at DESC, id DESC);

CREATE INDEX idx_config_application_status_tenant_version
    ON config_package_application_statuses (tenant_id, package_version, updated_at DESC, id DESC);
