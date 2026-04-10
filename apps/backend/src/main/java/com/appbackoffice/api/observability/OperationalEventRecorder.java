package com.appbackoffice.api.observability;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class OperationalEventRecorder {

    private final IntegrationOperationEventRepository eventRepository;
    private final ObjectMapper objectMapper;
    private final int retentionDays;

    public OperationalEventRecorder(IntegrationOperationEventRepository eventRepository,
                                    ObjectMapper objectMapper,
                                    @Value("${operations.control-tower.retention-days:30}") int retentionDays) {
        this.eventRepository = eventRepository;
        this.objectMapper = objectMapper;
        this.retentionDays = retentionDays;
    }

    public void recordHttpInteraction(HttpServletRequest request, HttpServletResponse response, long latencyMs) {
        String endpointKey = resolveEndpointKey(request.getRequestURI(), request.getMethod());
        if (endpointKey == null) {
            return;
        }

        IntegrationOperationEventEntity entity = new IntegrationOperationEventEntity();
        entity.setTenantId(trimToNull(request.getHeader("X-Tenant-Id")));
        entity.setChannel(resolveChannel(request.getRequestURI()));
        entity.setEventType("HTTP_INTERACTION");
        entity.setEndpointKey(endpointKey);
        entity.setHttpMethod(request.getMethod());
        entity.setHttpStatus(response.getStatus());
        entity.setOutcome(resolveOutcome(response.getStatus()));
        entity.setActorId(trimToNull(request.getHeader("X-Actor-Id")));
        entity.setCorrelationId((String) request.getAttribute(RequestTracingFilter.CORRELATION_ID_REQUEST_ATTRIBUTE));
        entity.setTraceId((String) request.getAttribute(RequestTracingFilter.TRACE_ID_REQUEST_ATTRIBUTE));
        entity.setLatencyMs(latencyMs);
        entity.setSummary(request.getMethod() + " " + endpointKey + " -> " + response.getStatus());
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("requestUri", request.getRequestURI());
        details.put("queryString", request.getQueryString());
        details.put("status", response.getStatus());
        details.put("latencyMs", latencyMs);
        entity.setDetailsJson(writeJson(details));
        entity.setRetentionUntil(Instant.now().plusSeconds(retentionDays * 24L * 60L * 60L));
        eventRepository.save(entity);
    }

    public void recordDomainEvent(String tenantId,
                                  String channel,
                                  String eventType,
                                  String endpointKey,
                                  String outcome,
                                  String actorId,
                                  String correlationId,
                                  String traceId,
                                  String protocolId,
                                  Long jobId,
                                  Long processId,
                                  Long reportId,
                                  boolean duplicateSubmission,
                                  String summary,
                                  Map<String, Object> details) {
        IntegrationOperationEventEntity entity = new IntegrationOperationEventEntity();
        entity.setTenantId(trimToNull(tenantId));
        entity.setChannel(channel);
        entity.setEventType(eventType);
        entity.setEndpointKey(endpointKey);
        entity.setOutcome(outcome);
        entity.setActorId(trimToNull(actorId));
        entity.setCorrelationId(trimToNull(correlationId));
        entity.setTraceId(trimToNull(traceId));
        entity.setProtocolId(trimToNull(protocolId));
        entity.setJobId(jobId);
        entity.setProcessId(processId);
        entity.setReportId(reportId);
        entity.setDuplicateSubmission(duplicateSubmission);
        entity.setSummary(summary);
        entity.setDetailsJson(writeJson(details));
        entity.setRetentionUntil(Instant.now().plusSeconds(retentionDays * 24L * 60L * 60L));
        eventRepository.save(entity);
    }

    private String resolveChannel(String requestUri) {
        if (requestUri == null) {
            return "UNKNOWN";
        }
        if (requestUri.startsWith("/api/mobile/")) {
            return "MOBILE";
        }
        return "BACKOFFICE";
    }

    private String resolveEndpointKey(String requestUri, String method) {
        if (requestUri == null || method == null) {
            return null;
        }
        if ("/api/mobile/checkin-config".equals(requestUri)) {
            return "mobile.checkin-config";
        }
        if ("/api/mobile/inspections/finalized".equals(requestUri)) {
            return "mobile.inspections.finalized";
        }
        if ("/api/mobile/config-packages/application-status".equals(requestUri)) {
            return "mobile.config-package-status";
        }
        if (requestUri.startsWith("/api/backoffice/config/packages/approve")) {
            return "backoffice.config.approve";
        }
        if (requestUri.startsWith("/api/backoffice/config/packages/rollback")) {
            return "backoffice.config.rollback";
        }
        if (requestUri.startsWith("/api/backoffice/config/packages")) {
            return "backoffice.config.packages";
        }
        if (requestUri.startsWith("/api/backoffice/inspections")) {
            return "backoffice.inspections";
        }
        if (requestUri.startsWith("/api/backoffice/valuation/processes")) {
            if ("POST".equalsIgnoreCase(method) && requestUri.endsWith("/validate-intake")) {
                return "backoffice.valuation.validate-intake";
            }
            return "backoffice.valuation.processes";
        }
        if (requestUri.startsWith("/api/backoffice/reports")) {
            if ("POST".equalsIgnoreCase(method) && requestUri.contains("/generate")) {
                return "backoffice.reports.generate";
            }
            if ("POST".equalsIgnoreCase(method) && requestUri.endsWith("/review")) {
                return "backoffice.reports.review";
            }
            return "backoffice.reports";
        }
        if (requestUri.startsWith("/api/backoffice/operations/control-tower")) {
            return "backoffice.operations.control-tower";
        }
        return null;
    }

    private String resolveOutcome(int httpStatus) {
        if (httpStatus >= 500) {
            return "ERROR";
        }
        if (httpStatus >= 400) {
            return "WARNING";
        }
        return "SUCCESS";
    }

    private String trimToNull(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }

    private String writeJson(Map<String, Object> details) {
        if (details == null || details.isEmpty()) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(details);
        } catch (JsonProcessingException exception) {
            return null;
        }
    }
}
