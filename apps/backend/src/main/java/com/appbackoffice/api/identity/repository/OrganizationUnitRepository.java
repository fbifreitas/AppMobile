package com.appbackoffice.api.identity.repository;

import com.appbackoffice.api.identity.entity.OrganizationUnit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrganizationUnitRepository extends JpaRepository<OrganizationUnit, Long> {
    List<OrganizationUnit> findByTenant_Id(String tenantId);
}
