package com.appbackoffice.api.observability;

import com.appbackoffice.api.config.ConfigPackageRepository;
import com.appbackoffice.api.config.ConfigPackageStatus;
import com.appbackoffice.api.identity.service.TenantGuardService;
import com.appbackoffice.api.observability.dto.OperationsControlTowerResponse;
import com.appbackoffice.api.valuation.entity.ReportStatus;
import com.appbackoffice.api.valuation.entity.ValuationProcessStatus;
import com.appbackoffice.api.valuation.repository.ReportRepository;
import com.appbackoffice.api.valuation.repository.ValuationProcessRepository;
import com.appbackoffice.api.mobile.repository.InspectionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class OperationsControlTowerService {

    private final TenantGuardService tenantGuardService;
    private final IntegrationOperationEventRepository eventRepository;
    private final InspectionRepository inspectionRepository;
    private final ValuationProcessRepository valuationProcessRepository;
    private final ReportRepository reportRepository;
    private final ConfigPackageRepository configPackageRepository;
    private final OperationsRetentionService retentionService;

    public OperationsControlTowerService(TenantGuardService tenantGuardService,
                                         IntegrationOperationEventRepository eventRepository,
                                         InspectionRepository inspectionRepository,
                                         ValuationProcessRepository valuationProcessRepository,
                                         ReportRepository reportRepository,
                                         ConfigPackageRepository configPackageRepository,
                                         OperationsRetentionService retentionService) {
        this.tenantGuardService = tenantGuardService;
        this.eventRepository = eventRepository;
        this.inspectionRepository = inspectionRepository;
        this.valuationProcessRepository = valuationProcessRepository;
        this.reportRepository = reportRepository;
        this.configPackageRepository = configPackageRepository;
        this.retentionService = retentionService;
    }

    @Transactional(readOnly = true)
    public OperationsControlTowerResponse getDashboard(String tenantId) {
        tenantGuardService.requireActiveTenant(tenantId);

        Instant now = Instant.now();
        Instant dayWindow = now.minus(24, ChronoUnit.HOURS);
        Instant alertWindow = now.minus(1, ChronoUnit.HOURS);

        List<IntegrationOperationEventEntity> recent24h = eventRepository
                .findTop1000ByTenantIdAndOccurredAtAfterOrderByOccurredAtDescIdDesc(tenantId, dayWindow);
        List<IntegrationOperationEventEntity> recentAll = eventRepository.findTop300ByTenantIdOrderByOccurredAtDescIdDesc(tenantId);

        List<IntegrationOperationEventEntity> requestEvents = recent24h.stream()
                .filter(item -> "HTTP_INTERACTION".equals(item.getEventType()))
                .toList();

        long errorRequests24h = requestEvents.stream()
                .filter(item -> "ERROR".equals(item.getOutcome()))
                .count();
        long retryOrDuplicateCount24h = recent24h.stream()
                .filter(item -> item.isDuplicateSubmission() || "RETRY".equals(item.getEventType()))
                .count();

        long pendingIntake = valuationProcessRepository.findByTenantIdAndStatusOrderByUpdatedAtDescIdDesc(
                tenantId, ValuationProcessStatus.PENDING_INTAKE).size();
        long processingValuations = valuationProcessRepository.findByTenantIdAndStatusOrderByUpdatedAtDescIdDesc(
                tenantId, ValuationProcessStatus.PROCESSING).size();
        long readyForSign = reportRepository.findByTenantIdAndStatusOrderByUpdatedAtDescIdDesc(
                tenantId, ReportStatus.READY_FOR_SIGN).size();
        long pendingConfigApprovals = configPackageRepository.findByTenantIdOrderByUpdatedAtAsc(tenantId).stream()
                .filter(item -> item.getStatus() == ConfigPackageStatus.PENDING_APPROVAL)
                .count();
        long operationalBacklog = pendingIntake + processingValuations + pendingConfigApprovals;

        List<OperationsControlTowerResponse.EndpointMetric> endpointMetrics = buildEndpointMetrics(requestEvents);
        List<OperationsControlTowerResponse.AlertItem> alerts = buildAlerts(
                tenantId,
                recent24h,
                recentAll,
                alertWindow,
                operationalBacklog,
                pendingIntake
        );
        List<OperationsControlTowerResponse.RecentEventItem> recentEvents = recentAll.stream()
                .limit(25)
                .map(item -> new OperationsControlTowerResponse.RecentEventItem(
                        item.getOccurredAt(),
                        item.getChannel(),
                        item.getEventType(),
                        item.getEndpointKey(),
                        item.getOutcome(),
                        item.getHttpStatus(),
                        item.getLatencyMs(),
                        item.getSummary(),
                        item.getCorrelationId(),
                        item.getTraceId(),
                        item.getProtocolId(),
                        item.getJobId(),
                        item.getProcessId(),
                        item.getReportId()
                ))
                .toList();

        var overview = new OperationsControlTowerResponse.Overview(
                requestEvents.size(),
                errorRequests24h,
                retryOrDuplicateCount24h,
                operationalBacklog,
                pendingIntake,
                readyForSign,
                pendingConfigApprovals,
                alerts.size()
        );

        Instant oldestRetained = eventRepository.findTopByTenantIdOrderByOccurredAtAscIdAsc(tenantId)
                .map(IntegrationOperationEventEntity::getOccurredAt)
                .orElse(null);
        long expiringEvents = eventRepository.countByTenantIdAndOccurredAtBefore(
                tenantId, now.minus(retentionService.getRetentionDays() - 1L, ChronoUnit.DAYS));

        var retention = new OperationsControlTowerResponse.RetentionSummary(
                retentionService.getRetentionDays(),
                eventRepository.countByTenantId(tenantId),
                expiringEvents,
                oldestRetained,
                retentionService.getLastCleanupAt(),
                retentionService.getLastDeletedCount()
        );

        var continuity = new OperationsControlTowerResponse.ContinuitySummary(
                alerts.stream().anyMatch(item -> "ERROR".equals(item.severity())) ? "ATTENTION_REQUIRED" : "READY",
                List.of(
                        new OperationsControlTowerResponse.ContinuitySummary.ChecklistItem(
                                "CT-001",
                                "READY",
                                "Correlation and trace propagation",
                                "Use X-Correlation-Id and X-Trace-Id from the control tower event list before opening raw backend logs."
                        ),
                        new OperationsControlTowerResponse.ContinuitySummary.ChecklistItem(
                                "CT-002",
                                operationalBacklog > 0 ? "ACTION_REQUIRED" : "READY",
                                "Operational backlog review",
                                "Review pending intake, processing valuations, and config packages before promoting new config or operational batch changes."
                        ),
                        new OperationsControlTowerResponse.ContinuitySummary.ChecklistItem(
                                "CT-003",
                                errorRequests24h > 0 ? "ACTION_REQUIRED" : "READY",
                                "Failure isolation procedure",
                                "Filter recent events by tenant, endpoint and protocolId, then decide between replay, rollback or manual intake handling."
                        )
                )
        );

        return new OperationsControlTowerResponse(
                now,
                overview,
                endpointMetrics,
                alerts,
                recentEvents,
                retention,
                continuity
        );
    }

    private List<OperationsControlTowerResponse.EndpointMetric> buildEndpointMetrics(List<IntegrationOperationEventEntity> requestEvents) {
        Map<String, List<IntegrationOperationEventEntity>> byEndpoint = new LinkedHashMap<>();
        for (IntegrationOperationEventEntity item : requestEvents) {
            if (item.getEndpointKey() == null) {
                continue;
            }
            byEndpoint.computeIfAbsent(item.getEndpointKey(), ignored -> new ArrayList<>()).add(item);
        }

        return byEndpoint.entrySet().stream()
                .map(entry -> {
                    List<IntegrationOperationEventEntity> items = entry.getValue();
                    List<Long> latencies = items.stream()
                            .map(IntegrationOperationEventEntity::getLatencyMs)
                            .filter(value -> value != null && value >= 0)
                            .sorted()
                            .toList();
                    long p95Latency = latencies.isEmpty() ? 0 : latencies.get(Math.max(0, (int) Math.ceil(latencies.size() * 0.95) - 1));
                    IntegrationOperationEventEntity latest = items.stream()
                            .max(Comparator.comparing(IntegrationOperationEventEntity::getOccurredAt))
                            .orElse(items.get(0));
                    return new OperationsControlTowerResponse.EndpointMetric(
                            entry.getKey(),
                            items.size(),
                            items.stream().filter(item -> "SUCCESS".equals(item.getOutcome())).count(),
                            items.stream().filter(item -> "WARNING".equals(item.getOutcome())).count(),
                            items.stream().filter(item -> "ERROR".equals(item.getOutcome())).count(),
                            items.stream().filter(IntegrationOperationEventEntity::isDuplicateSubmission).count(),
                            p95Latency,
                            latest.getHttpStatus(),
                            latest.getOccurredAt()
                    );
                })
                .sorted(Comparator.comparing(OperationsControlTowerResponse.EndpointMetric::endpointKey))
                .toList();
    }

    private List<OperationsControlTowerResponse.AlertItem> buildAlerts(String tenantId,
                                                                       List<IntegrationOperationEventEntity> recent24h,
                                                                       List<IntegrationOperationEventEntity> recentAll,
                                                                       Instant alertWindow,
                                                                       long operationalBacklog,
                                                                       long pendingIntake) {
        List<OperationsControlTowerResponse.AlertItem> alerts = new ArrayList<>();

        Map<String, Long> errorsByEndpoint = recent24h.stream()
                .filter(item -> "HTTP_INTERACTION".equals(item.getEventType()))
                .filter(item -> "ERROR".equals(item.getOutcome()))
                .filter(item -> item.getEndpointKey() != null)
                .collect(LinkedHashMap::new, (map, item) -> map.merge(item.getEndpointKey(), 1L, Long::sum), Map::putAll);

        errorsByEndpoint.forEach((endpointKey, count) -> alerts.add(new OperationsControlTowerResponse.AlertItem(
                "ERR_" + endpointKey.toUpperCase().replace('.', '_'),
                count >= 3 ? "ERROR" : "WARNING",
                "Error burst detected",
                "Recent backend errors detected for the endpoint.",
                endpointKey,
                count,
                latestTimestamp(recent24h, endpointKey, "ERROR")
        )));

        long duplicateSubmissions = recent24h.stream().filter(IntegrationOperationEventEntity::isDuplicateSubmission).count();
        if (duplicateSubmissions > 0) {
            alerts.add(new OperationsControlTowerResponse.AlertItem(
                    "DUPLICATE_SUBMISSIONS",
                    "WARNING",
                    "Duplicate inspection submissions detected",
                    "At least one finalized inspection submission was retried with duplicate payload semantics.",
                    "mobile.inspections.finalized",
                    duplicateSubmissions,
                    latestDuplicateTimestamp(recent24h)
            ));
        }

        if (operationalBacklog > 0) {
            alerts.add(new OperationsControlTowerResponse.AlertItem(
                    "OPERATIONAL_BACKLOG",
                    operationalBacklog >= 10 ? "ERROR" : "WARNING",
                    "Operational backlog requires review",
                    "Pending intake, processing valuations or config approvals are waiting for backoffice action.",
                    "backoffice.operations.control-tower",
                    operationalBacklog,
                    Instant.now()
            ));
        }

        boolean staleFlow = recentAll.stream()
                .noneMatch(item -> item.getOccurredAt() != null
                        && item.getOccurredAt().isAfter(alertWindow)
                        && tenantId.equals(item.getTenantId()));
        if (staleFlow && pendingIntake > 0) {
            alerts.add(new OperationsControlTowerResponse.AlertItem(
                    "STALE_INTEGRATION_FLOW",
                    "WARNING",
                    "No recent operational events",
                    "There are pending intake items without fresh event activity in the last hour.",
                    "backoffice.operations.control-tower",
                    pendingIntake,
                    Instant.now()
            ));
        }

        return alerts.stream()
                .sorted(Comparator.comparing(OperationsControlTowerResponse.AlertItem::severity).reversed()
                        .thenComparing(OperationsControlTowerResponse.AlertItem::triggeredAt, Comparator.nullsLast(Comparator.reverseOrder())))
                .toList();
    }

    private Instant latestTimestamp(List<IntegrationOperationEventEntity> items, String endpointKey, String outcome) {
        return items.stream()
                .filter(item -> endpointKey.equals(item.getEndpointKey()))
                .filter(item -> outcome.equals(item.getOutcome()))
                .map(IntegrationOperationEventEntity::getOccurredAt)
                .max(Comparator.naturalOrder())
                .orElse(null);
    }

    private Instant latestDuplicateTimestamp(List<IntegrationOperationEventEntity> items) {
        return items.stream()
                .filter(IntegrationOperationEventEntity::isDuplicateSubmission)
                .map(IntegrationOperationEventEntity::getOccurredAt)
                .max(Comparator.naturalOrder())
                .orElse(null);
    }
}
