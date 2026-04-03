-- V003: Remove coluna role de users (campo migrado para memberships)
ALTER TABLE users DROP COLUMN role;
