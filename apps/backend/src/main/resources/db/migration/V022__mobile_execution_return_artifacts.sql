CREATE TABLE inspection_return_artifacts (
    id BIGSERIAL PRIMARY KEY,
    inspection_id BIGINT NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
    submission_id BIGINT REFERENCES inspection_submissions(id) ON DELETE SET NULL,
    tenant_id VARCHAR(255) NOT NULL REFERENCES tenants(id),
    case_id BIGINT NOT NULL REFERENCES inspection_cases(id) ON DELETE CASCADE,
    job_id BIGINT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    execution_plan_snapshot_id BIGINT REFERENCES execution_plan_snapshots(id) ON DELETE SET NULL,
    raw_storage_key VARCHAR(255) NOT NULL,
    normalized_storage_key VARCHAR(255) NOT NULL,
    summary_json TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_inspection_return_artifacts_case_created
    ON inspection_return_artifacts(case_id, created_at DESC);

CREATE TABLE field_evidence_records (
    id BIGSERIAL PRIMARY KEY,
    inspection_id BIGINT NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
    tenant_id VARCHAR(255) NOT NULL REFERENCES tenants(id),
    case_id BIGINT NOT NULL REFERENCES inspection_cases(id) ON DELETE CASCADE,
    job_id BIGINT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    source_section VARCHAR(80) NOT NULL,
    macro_location VARCHAR(160),
    environment_name VARCHAR(160),
    element_name VARCHAR(160),
    required_flag BOOLEAN NOT NULL DEFAULT FALSE,
    min_photos INTEGER,
    captured_photos INTEGER,
    evidence_status VARCHAR(40) NOT NULL,
    evidence_json TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_field_evidence_records_inspection
    ON field_evidence_records(inspection_id, created_at DESC);
