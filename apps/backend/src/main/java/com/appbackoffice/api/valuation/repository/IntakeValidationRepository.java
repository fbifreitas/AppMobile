package com.appbackoffice.api.valuation.repository;

import com.appbackoffice.api.valuation.entity.IntakeValidationEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface IntakeValidationRepository extends JpaRepository<IntakeValidationEntity, Long> {
    Optional<IntakeValidationEntity> findTopByValuationProcessIdOrderByValidatedAtDescIdDesc(Long valuationProcessId);
}
