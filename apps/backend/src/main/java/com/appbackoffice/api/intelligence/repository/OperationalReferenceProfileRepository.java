package com.appbackoffice.api.intelligence.repository;

import com.appbackoffice.api.intelligence.entity.OperationalReferenceProfileEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface OperationalReferenceProfileRepository extends JpaRepository<OperationalReferenceProfileEntity, Long> {
    List<OperationalReferenceProfileEntity> findByActiveFlagTrueOrderByPriorityWeightDescIdAsc();
    List<OperationalReferenceProfileEntity> findAllByOrderByPriorityWeightDescIdAsc();
}
