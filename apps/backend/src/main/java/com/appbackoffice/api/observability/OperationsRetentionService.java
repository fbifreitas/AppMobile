package com.appbackoffice.api.observability;

import com.appbackoffice.api.observability.dto.RetentionExecutionResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;

@Service
public class OperationsRetentionService {

    private final IntegrationOperationEventRepository eventRepository;
    private final int retentionDays;
    private final AtomicReference<Instant> lastCleanupAt = new AtomicReference<>();
    private final AtomicLong lastDeletedCount = new AtomicLong();

    public OperationsRetentionService(IntegrationOperationEventRepository eventRepository,
                                      @Value("${operations.control-tower.retention-days:30}") int retentionDays) {
        this.eventRepository = eventRepository;
        this.retentionDays = retentionDays;
    }

    @Transactional
    @Scheduled(cron = "${operations.control-tower.retention-cron:0 15 3 * * *}", zone = "UTC")
    public void scheduledCleanup() {
        executeCleanup();
    }

    @Transactional
    public RetentionExecutionResponse runRetentionNow() {
        long deleted = executeCleanup();
        return new RetentionExecutionResponse(lastCleanupAt.get(), retentionDays, deleted);
    }

    public int getRetentionDays() {
        return retentionDays;
    }

    public Instant getLastCleanupAt() {
        return lastCleanupAt.get();
    }

    public long getLastDeletedCount() {
        return lastDeletedCount.get();
    }

    private long executeCleanup() {
        Instant executedAt = Instant.now();
        Instant cutoff = executedAt.minus(retentionDays, ChronoUnit.DAYS);
        long deleted = eventRepository.deleteByOccurredAtBefore(cutoff);
        lastCleanupAt.set(executedAt);
        lastDeletedCount.set(deleted);
        return deleted;
    }
}
