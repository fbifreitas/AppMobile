CREATE TABLE integration_operation_events (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(120),
    channel VARCHAR(40) NOT NULL,
    event_type VARCHAR(80) NOT NULL,
    endpoint_key VARCHAR(160),
    http_method VARCHAR(16),
    http_status INTEGER,
    outcome VARCHAR(24) NOT NULL,
    actor_id VARCHAR(120),
    correlation_id VARCHAR(160),
    trace_id VARCHAR(160),
    protocol_id VARCHAR(160),
    job_id BIGINT,
    process_id BIGINT,
    report_id BIGINT,
    duplicate_submission BOOLEAN NOT NULL DEFAULT FALSE,
    latency_ms BIGINT,
    summary VARCHAR(512),
    details_json TEXT,
    occurred_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    retention_until TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_integration_operation_events_tenant_occurred_at
    ON integration_operation_events (tenant_id, occurred_at DESC);

CREATE INDEX idx_integration_operation_events_endpoint_occurred_at
    ON integration_operation_events (endpoint_key, occurred_at DESC);

CREATE INDEX idx_integration_operation_events_protocol_id
    ON integration_operation_events (protocol_id);

CREATE INDEX idx_integration_operation_events_correlation_id
    ON integration_operation_events (correlation_id);
