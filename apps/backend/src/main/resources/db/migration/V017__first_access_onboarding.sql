ALTER TABLE users ADD COLUMN birth_date DATE;
ALTER TABLE users ADD COLUMN phone VARCHAR(40);

CREATE TABLE first_access_otps (
    id          VARCHAR(255) NOT NULL,
    tenant_id   VARCHAR(255) NOT NULL,
    user_id     BIGINT       NOT NULL,
    otp_hash    VARCHAR(255) NOT NULL,
    expires_at  TIMESTAMP    NOT NULL,
    attempts    INT          NOT NULL,
    consumed_at TIMESTAMP,
    created_at  TIMESTAMP    NOT NULL,
    updated_at  TIMESTAMP    NOT NULL,
    CONSTRAINT pk_first_access_otps PRIMARY KEY (id),
    CONSTRAINT fk_first_access_otps_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_first_access_otps_tenant_user ON first_access_otps(tenant_id, user_id);
