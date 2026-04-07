-- Normalize timestamp columns to TIMESTAMPTZ so Hibernate 6 Instant mapping
-- works correctly with PostgreSQL. Columns were created as TIMESTAMP (without
-- timezone) in V001 but Hibernate 6 maps java.time.Instant to TIMESTAMP WITH
-- TIME ZONE. Without this, INSERT/UPDATE on these entities fails at runtime
-- on real PostgreSQL (H2 in PostgreSQL-mode is lenient and does not fail).

ALTER TABLE config_packages
    ALTER COLUMN updated_at TYPE TIMESTAMPTZ
    USING updated_at AT TIME ZONE 'UTC';

ALTER TABLE config_packages
    ALTER COLUMN rollout_starts_at TYPE TIMESTAMPTZ
    USING rollout_starts_at AT TIME ZONE 'UTC';

ALTER TABLE config_packages
    ALTER COLUMN rollout_ends_at TYPE TIMESTAMPTZ
    USING rollout_ends_at AT TIME ZONE 'UTC';

ALTER TABLE config_audit_entries
    ALTER COLUMN created_at TYPE TIMESTAMPTZ
    USING created_at AT TIME ZONE 'UTC';
