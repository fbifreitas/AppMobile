package com.appbackoffice.api.identity.repository;

import com.appbackoffice.api.identity.entity.Membership;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MembershipRepository extends JpaRepository<Membership, Long> {
    Optional<Membership> findByUser_IdAndTenant_Id(Long userId, String tenantId);

    List<Membership> findByTenant_Id(String tenantId);
}
