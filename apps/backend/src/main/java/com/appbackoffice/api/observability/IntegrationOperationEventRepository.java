package com.appbackoffice.api.observability;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface IntegrationOperationEventRepository extends JpaRepository<IntegrationOperationEventEntity, Long> {

    List<IntegrationOperationEventEntity> findTop300ByTenantIdOrderByOccurredAtDescIdDesc(String tenantId);

    List<IntegrationOperationEventEntity> findTop1000ByTenantIdAndOccurredAtAfterOrderByOccurredAtDescIdDesc(String tenantId, Instant occurredAfter);

    Optional<IntegrationOperationEventEntity> findTopByTenantIdOrderByOccurredAtAscIdAsc(String tenantId);

    long countByTenantId(String tenantId);

    long countByTenantIdAndOccurredAtBefore(String tenantId, Instant cutoff);

    long deleteByOccurredAtBefore(Instant cutoff);
}
