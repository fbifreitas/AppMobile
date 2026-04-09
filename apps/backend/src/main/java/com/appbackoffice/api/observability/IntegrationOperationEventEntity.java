package com.appbackoffice.api.observability;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(name = "integration_operation_events")
public class IntegrationOperationEventEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id")
    private String tenantId;

    @Column(name = "channel", nullable = false)
    private String channel;

    @Column(name = "event_type", nullable = false)
    private String eventType;

    @Column(name = "endpoint_key")
    private String endpointKey;

    @Column(name = "http_method")
    private String httpMethod;

    @Column(name = "http_status")
    private Integer httpStatus;

    @Column(name = "outcome", nullable = false)
    private String outcome;

    @Column(name = "actor_id")
    private String actorId;

    @Column(name = "correlation_id")
    private String correlationId;

    @Column(name = "trace_id")
    private String traceId;

    @Column(name = "protocol_id")
    private String protocolId;

    @Column(name = "job_id")
    private Long jobId;

    @Column(name = "process_id")
    private Long processId;

    @Column(name = "report_id")
    private Long reportId;

    @Column(name = "duplicate_submission", nullable = false)
    private boolean duplicateSubmission;

    @Column(name = "latency_ms")
    private Long latencyMs;

    @Column(name = "summary")
    private String summary;

    @Column(name = "details_json", columnDefinition = "TEXT")
    private String detailsJson;

    @CreationTimestamp
    @Column(name = "occurred_at", nullable = false, updatable = false)
    private Instant occurredAt;

    @Column(name = "retention_until")
    private Instant retentionUntil;

    public Long getId() {
        return id;
    }

    public String getTenantId() {
        return tenantId;
    }

    public void setTenantId(String tenantId) {
        this.tenantId = tenantId;
    }

    public String getChannel() {
        return channel;
    }

    public void setChannel(String channel) {
        this.channel = channel;
    }

    public String getEventType() {
        return eventType;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public String getEndpointKey() {
        return endpointKey;
    }

    public void setEndpointKey(String endpointKey) {
        this.endpointKey = endpointKey;
    }

    public String getHttpMethod() {
        return httpMethod;
    }

    public void setHttpMethod(String httpMethod) {
        this.httpMethod = httpMethod;
    }

    public Integer getHttpStatus() {
        return httpStatus;
    }

    public void setHttpStatus(Integer httpStatus) {
        this.httpStatus = httpStatus;
    }

    public String getOutcome() {
        return outcome;
    }

    public void setOutcome(String outcome) {
        this.outcome = outcome;
    }

    public String getActorId() {
        return actorId;
    }

    public void setActorId(String actorId) {
        this.actorId = actorId;
    }

    public String getCorrelationId() {
        return correlationId;
    }

    public void setCorrelationId(String correlationId) {
        this.correlationId = correlationId;
    }

    public String getTraceId() {
        return traceId;
    }

    public void setTraceId(String traceId) {
        this.traceId = traceId;
    }

    public String getProtocolId() {
        return protocolId;
    }

    public void setProtocolId(String protocolId) {
        this.protocolId = protocolId;
    }

    public Long getJobId() {
        return jobId;
    }

    public void setJobId(Long jobId) {
        this.jobId = jobId;
    }

    public Long getProcessId() {
        return processId;
    }

    public void setProcessId(Long processId) {
        this.processId = processId;
    }

    public Long getReportId() {
        return reportId;
    }

    public void setReportId(Long reportId) {
        this.reportId = reportId;
    }

    public boolean isDuplicateSubmission() {
        return duplicateSubmission;
    }

    public void setDuplicateSubmission(boolean duplicateSubmission) {
        this.duplicateSubmission = duplicateSubmission;
    }

    public Long getLatencyMs() {
        return latencyMs;
    }

    public void setLatencyMs(Long latencyMs) {
        this.latencyMs = latencyMs;
    }

    public String getSummary() {
        return summary;
    }

    public void setSummary(String summary) {
        this.summary = summary;
    }

    public String getDetailsJson() {
        return detailsJson;
    }

    public void setDetailsJson(String detailsJson) {
        this.detailsJson = detailsJson;
    }

    public Instant getOccurredAt() {
        return occurredAt;
    }

    public Instant getRetentionUntil() {
        return retentionUntil;
    }

    public void setRetentionUntil(Instant retentionUntil) {
        this.retentionUntil = retentionUntil;
    }
}
