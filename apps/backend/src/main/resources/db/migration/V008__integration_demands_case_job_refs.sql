-- V008: Link Integration Hub demand intake to case/job aggregate (BOW-120 continuation)
ALTER TABLE integration_demands
    ADD COLUMN case_id BIGINT;

ALTER TABLE integration_demands
    ADD COLUMN job_id BIGINT;

ALTER TABLE integration_demands
    ADD CONSTRAINT fk_integration_demands_case FOREIGN KEY (case_id) REFERENCES inspection_cases(id);

ALTER TABLE integration_demands
    ADD CONSTRAINT fk_integration_demands_job FOREIGN KEY (job_id) REFERENCES jobs(id);
