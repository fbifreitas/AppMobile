package com.appbackoffice.api.mobile;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.CanonicalErrorResponse;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.job.dto.JobSummaryResponse;
import com.appbackoffice.api.job.service.JobService;
import com.appbackoffice.api.mobile.dto.CheckinConfigResponse;
import com.appbackoffice.api.mobile.dto.InspectionFinalizedRequest;
import com.appbackoffice.api.mobile.dto.InspectionFinalizedResponse;
import com.appbackoffice.api.mobile.service.InspectionSubmissionService;
import com.appbackoffice.api.mobile.service.MobileCheckinConfigService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@Validated
@RequestMapping("/api/mobile")
@Tag(name = "Mobile v1", description = "Contratos críticos do AppMobile (v1)")
public class MobileApiController {

    private final JobService jobService;
        private final InspectionSubmissionService inspectionSubmissionService;
        private final MobileCheckinConfigService mobileCheckinConfigService;

        public MobileApiController(JobService jobService,
                                                           InspectionSubmissionService inspectionSubmissionService,
                                                           MobileCheckinConfigService mobileCheckinConfigService) {
        this.jobService = jobService;
                this.inspectionSubmissionService = inspectionSubmissionService;
                this.mobileCheckinConfigService = mobileCheckinConfigService;
    }

    @GetMapping("/checkin-config")
    @Operation(
            summary = "Retorna configuração dinâmica de check-in (v1)",
            description = "Contrato retrocompatível: em v1, apenas adições não quebrantes são permitidas.",
            responses = {
                    @ApiResponse(responseCode = "200", description = "Configuração retornada com sucesso"),
                    @ApiResponse(
                            responseCode = "400",
                            description = "Contexto inválido",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    )
            }
    )
    public ResponseEntity<CheckinConfigResponse> getCheckinConfig(
            @Parameter(description = "Tipo do imóvel")
            @RequestParam(required = false) String tipoImovel,
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId
    ) {
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        return ResponseEntity.ok(mobileCheckinConfigService.resolve(tenantId, actorId, tipoImovel));
    }

    @PostMapping("/inspections/finalized")
    @Operation(
            summary = "Recebe payload finalizado de inspeção (v1)",
            description = "Operação idempotente por X-Idempotency-Key.",
            responses = {
                    @ApiResponse(responseCode = "202", description = "Payload aceito para processamento"),
                    @ApiResponse(
                            responseCode = "400",
                            description = "Requisição inválida",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    ),
                    @ApiResponse(
                            responseCode = "409",
                            description = "Conflito de idempotência",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    )
            }
    )
    public ResponseEntity<InspectionFinalizedResponse> postInspectionFinalized(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @RequestHeader("X-Idempotency-Key") String idempotencyKey,
            @Valid @RequestBody InspectionFinalizedRequest request
    ) {
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        if (!org.springframework.util.StringUtils.hasText(idempotencyKey)) {
                        throw new ApiContractException(
                                        HttpStatus.BAD_REQUEST,
                                        "IDEMPOTENCY_KEY_REQUIRED",
                                        "X-Idempotency-Key é obrigatório",
                                        ErrorSeverity.ERROR,
                                        "Informe X-Idempotency-Key para garantir processamento seguro em retries.",
                                        "header: X-Idempotency-Key"
                        );
        }

        Long userId = parseUserId(actorId);
        InspectionFinalizedResponse created = inspectionSubmissionService.receive(
                tenantId,
                userId,
                actorId,
                idempotencyKey,
                request
        );
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(created);
    }

    @GetMapping("/jobs")
    @Operation(
            summary = "Lista jobs do vistoriador autenticado (v1)",
            description = "Retorna jobs atribuídos ao userId informado. Usa X-Actor-Id como identificador do vistoriador.",
            responses = {
                    @ApiResponse(responseCode = "200", description = "Lista de jobs retornada"),
                    @ApiResponse(
                            responseCode = "400",
                            description = "Contexto inválido",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    )
            }
    )
    public ResponseEntity<List<JobSummaryResponse>> getMobileJobs(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @Parameter(description = "Filtro por status (ex: ACCEPTED, IN_EXECUTION). Padrão: ACCEPTED")
            @RequestParam(required = false) String status
    ) {
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        Long userId = parseUserId(actorId);
                return ResponseEntity.ok(jobService.getMobileJobsForUser(tenantId, userId, status));
    }

    private Long parseUserId(String actorId) {
        try {
            return Long.parseLong(actorId);
        } catch (NumberFormatException e) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "INVALID_ACTOR_ID",
                    "X-Actor-Id deve ser um ID numérico de usuário",
                    ErrorSeverity.ERROR,
                    "Informe o ID interno do usuário no cabeçalho X-Actor-Id.",
                    "header: X-Actor-Id"
            );
        }
    }

}
