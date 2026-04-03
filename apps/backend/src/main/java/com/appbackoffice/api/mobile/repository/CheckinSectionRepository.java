package com.appbackoffice.api.mobile.repository;

import com.appbackoffice.api.mobile.entity.CheckinSectionEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CheckinSectionRepository extends JpaRepository<CheckinSectionEntity, Long> {

    List<CheckinSectionEntity> findByTenantIdAndActiveTrueOrderBySortOrderAscUpdatedAtAsc(String tenantId);
}
