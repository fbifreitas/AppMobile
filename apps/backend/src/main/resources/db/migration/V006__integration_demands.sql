-- V006: Integration Hub demand intake (BOW-110)
CREATE TABLE integration_demands (
    id                    VARCHAR(64)  NOT NULL,
    external_id           VARCHAR(128) NOT NULL,
    tenant_id             VARCHAR(255) NOT NULL,
    requested_by          VARCHAR(120) NOT NULL,
    inspection_type       VARCHAR(40)  NOT NULL,
    requested_deadline    TIMESTAMP    NOT NULL,
    property_address_json TEXT         NOT NULL,
    client_data_json      TEXT,
    normalized_payload    TEXT         NOT NULL,
    status                VARCHAR(40)  NOT NULL,
    created_at            TIMESTAMP    NOT NULL,
    updated_at            TIMESTAMP    NOT NULL,
    CONSTRAINT pk_integration_demands PRIMARY KEY (id),
    CONSTRAINT uq_integration_demands_external UNIQUE (external_id),
    CONSTRAINT fk_integration_demands_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);
