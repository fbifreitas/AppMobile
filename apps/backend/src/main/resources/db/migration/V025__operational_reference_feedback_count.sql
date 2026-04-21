ALTER TABLE operational_reference_profiles
    ADD COLUMN IF NOT EXISTS feedback_count INTEGER NOT NULL DEFAULT 0;
