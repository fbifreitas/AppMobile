CREATE TABLE operational_reference_profiles (
    id BIGSERIAL PRIMARY KEY,
    tenant_id VARCHAR(120),
    scope_type VARCHAR(60) NOT NULL,
    source_type VARCHAR(60) NOT NULL,
    active_flag BOOLEAN NOT NULL DEFAULT TRUE,
    asset_type VARCHAR(120) NOT NULL,
    asset_subtype VARCHAR(160) NOT NULL,
    refined_asset_subtype VARCHAR(160),
    property_standard VARCHAR(120),
    region_state VARCHAR(120),
    region_city VARCHAR(160),
    region_district VARCHAR(160),
    priority_weight INTEGER NOT NULL DEFAULT 100,
    confidence_score DOUBLE PRECISION,
    candidate_subtypes_json TEXT,
    photo_locations_json TEXT,
    composition_json TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_operational_reference_profiles_lookup
    ON operational_reference_profiles(active_flag, asset_type, asset_subtype, scope_type, priority_weight DESC);
