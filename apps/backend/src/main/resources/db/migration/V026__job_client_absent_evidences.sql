CREATE TABLE job_client_absent_evidences (
    id BIGSERIAL PRIMARY KEY,
    job_id BIGINT NOT NULL,
    tenant_id VARCHAR(100) NOT NULL,
    actor_id VARCHAR(100),
    responder_name VARCHAR(255) NOT NULL,
    reason TEXT,
    storage_key VARCHAR(500) NOT NULL,
    public_url VARCHAR(500),
    content_type VARCHAR(120),
    captured_at TIMESTAMP WITH TIME ZONE NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    accuracy DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_job_client_absent_evidences_job_created
    ON job_client_absent_evidences(job_id, created_at DESC);
