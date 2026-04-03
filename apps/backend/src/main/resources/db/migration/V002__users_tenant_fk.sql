-- V002: FK real users.tenant_id -> tenants.id
ALTER TABLE users
    ADD CONSTRAINT fk_users_tenant_id
        FOREIGN KEY (tenant_id) REFERENCES tenants(id);
