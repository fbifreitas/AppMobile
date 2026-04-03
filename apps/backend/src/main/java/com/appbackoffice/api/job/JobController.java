package com.appbackoffice.api.job;

import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.job.dto.AssignJobRequest;
import com.appbackoffice.api.job.dto.CancelJobRequest;
import com.appbackoffice.api.job.dto.JobDetailResponse;
import com.appbackoffice.api.job.dto.JobSummaryResponse;
import com.appbackoffice.api.job.dto.JobTimelineResponse;
import com.appbackoffice.api.job.service.JobService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Validated
@RequestMapping("/jobs")
@Tag(name = "Jobs", description = "Ciclo de vida de jobs de vistoria")
public class JobController {

    private final JobService jobService;

    public JobController(JobService jobService) {
        this.jobService = jobService;
    }

    @GetMapping
    @Operation(summary = "Lista jobs por tenant com filtro opcional de status")
    public ResponseEntity<Page<JobSummaryResponse>> listJobs(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        PageRequest pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        return ResponseEntity.ok(jobService.listJobs(tenantId, status, pageable));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Retorna detalhes de um job incluindo assignments")
    public ResponseEntity<JobDetailResponse> getJob(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @PathVariable Long id
    ) {
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        return ResponseEntity.ok(jobService.getJobDetail(tenantId, id));
    }

    @GetMapping("/{id}/timeline")
    @Operation(summary = "Retorna histórico de transições de estado do job")
    public ResponseEntity<JobTimelineResponse> getTimeline(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @PathVariable Long id
    ) {
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        return ResponseEntity.ok(jobService.getTimeline(tenantId, id));
    }

    @PostMapping("/{id}/assign")
    @Operation(summary = "Despacha job para vistoriador (ELIGIBLE_FOR_DISPATCH → OFFERED)")
    public ResponseEntity<JobSummaryResponse> assign(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @PathVariable Long id,
            @Valid @RequestBody AssignJobRequest request
    ) {
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        return ResponseEntity.ok(jobService.assignJob(tenantId, id, request, actorId));
    }

    @PostMapping("/{id}/accept")
    @Operation(summary = "Vistoriador aceita job (OFFERED → ACCEPTED)")
    public ResponseEntity<JobSummaryResponse> accept(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @PathVariable Long id
    ) {
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        return ResponseEntity.ok(jobService.acceptJob(tenantId, id, actorId));
    }

    @PostMapping("/{id}/cancel")
    @Operation(summary = "Cancela job com motivo (qualquer estado → CLOSED)")
    public ResponseEntity<JobSummaryResponse> cancel(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @PathVariable Long id,
            @RequestBody(required = false) CancelJobRequest request
    ) {
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        String reason = request != null ? request.reason() : null;
        return ResponseEntity.ok(jobService.cancelJob(tenantId, id, reason, actorId));
    }
}
