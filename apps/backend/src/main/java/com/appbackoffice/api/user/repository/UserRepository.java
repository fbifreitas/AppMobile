package com.appbackoffice.api.user.repository;

import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserSource;
import com.appbackoffice.api.user.entity.UserStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.time.LocalDate;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    List<User> findByTenantId(String tenantId);

    List<User> findByTenantIdAndStatus(String tenantId, UserStatus status);

    List<User> findByTenantIdAndSource(String tenantId, UserSource source);

    Optional<User> findByTenantIdAndId(String tenantId, Long userId);

    Optional<User> findByTenantIdAndEmail(String tenantId, String email);

    Optional<User> findByTenantIdAndExternalId(String tenantId, String externalId);

    Optional<User> findByTenantIdAndCpfAndBirthDateAndExternalId(
            String tenantId,
            String cpf,
            LocalDate birthDate,
            String externalId
    );
}
