CREATE TABLE case_enrichment_runs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(120) NOT NULL,
    case_id BIGINT NOT NULL REFERENCES inspection_cases(id) ON DELETE CASCADE,
    provider_name VARCHAR(120) NOT NULL,
    model_name VARCHAR(160),
    prompt_version VARCHAR(80),
    status VARCHAR(40) NOT NULL,
    request_storage_key VARCHAR(255),
    response_raw_storage_key VARCHAR(255),
    response_normalized_storage_key VARCHAR(255),
    facts_json TEXT,
    quality_flags_json TEXT,
    confidence_score DOUBLE PRECISION,
    error_code VARCHAR(120),
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_case_enrichment_runs_case_created
    ON case_enrichment_runs(case_id, created_at DESC);

CREATE TABLE execution_plan_snapshots (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(120) NOT NULL,
    case_id BIGINT NOT NULL REFERENCES inspection_cases(id) ON DELETE CASCADE,
    source_run_id BIGINT REFERENCES case_enrichment_runs(id) ON DELETE SET NULL,
    status VARCHAR(40) NOT NULL,
    plan_json TEXT NOT NULL,
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_execution_plan_snapshots_case_created
    ON execution_plan_snapshots(case_id, created_at DESC);
