-- V020: Rename persisted inspection and check-in columns to neutral names
ALTER TABLE inspection_submissions RENAME COLUMN vistoriador_id TO field_agent_id;
ALTER TABLE inspections RENAME COLUMN vistoriador_id TO field_agent_id;
ALTER TABLE checkin_sections RENAME COLUMN tipo_imovel TO asset_type;
