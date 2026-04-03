package com.appbackoffice.api.user.repository;

import com.appbackoffice.api.user.entity.UserLifecycle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserLifecycleRepository extends JpaRepository<UserLifecycle, Long> {
    Optional<UserLifecycle> findByUserIdAndTenantId(Long userId, String tenantId);
}
