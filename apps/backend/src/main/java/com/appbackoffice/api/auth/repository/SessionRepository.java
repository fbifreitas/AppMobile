package com.appbackoffice.api.auth.repository;

import com.appbackoffice.api.auth.entity.SessionEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SessionRepository extends JpaRepository<SessionEntity, String> {
    Optional<SessionEntity> findByRefreshTokenHashAndRevokedAtIsNull(String refreshTokenHash);
}
