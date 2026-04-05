package com.appbackoffice.api.mobile;

import com.appbackoffice.api.config.ConfigPayloadSignatureService;
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
import com.fasterxml.jackson.databind.ObjectMapper;
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
@Tag(name = "Mobile v1", description = "Contratos criticos do AppMobile (v1)")
public class MobileApiController {

    private final JobService jobService;
    private final InspectionSubmissionService inspectionSubmissionService;
    private final MobileCheckinConfigService mobileCheckinConfigService;
    private final ConfigPayloadSignatureService configPayloadSignatureService;
    private final ObjectMapper objectMapper;

    public MobileApiController(JobService jobService,
                               InspectionSubmissionService inspectionSubmissionService,
                               MobileCheckinConfigService mobileCheckinConfigService,
                               ConfigPayloadSignatureService configPayloadSignatureService,
                               ObjectMapper objectMapper) {
        this.jobService = jobService;
        this.inspectionSubmissionService = inspectionSubmissionService;
        this.mobileCheckinConfigService = mobileCheckinConfigService;
        this.configPayloadSignatureService = configPayloadSignatureService;
        this.objectMapper = objectMapper;
    }

    @GetMapping("/checkin-config")
    @Operation(
            summary = "Retorna configuracao dinamica de check-in (v1)",
            description = "Contrato retrocompativel: em v1, apenas adicoes nao quebrantes sao permitidas.",
            responses = {
                    @ApiResponse(responseCode = "200", description = "Configuracao retornada com sucesso"),
                    @ApiResponse(
                            responseCode = "400",
                            description = "Contexto invalido",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    )
            }
    )
    public ResponseEntity<CheckinConfigResponse> getCheckinConfig(
            @Parameter(description = "Tipo do imovel")
            @RequestParam(required = false) String tipoImovel,
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @RequestHeader("X-Api-Version") String apiVersion
    ) {
        RequestContextValidator.requireApiVersion(apiVersion);
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);

        CheckinConfigResponse response = mobileCheckinConfigService.resolve(tenantId, actorId, tipoImovel);
        ResponseEntity.BodyBuilder builder = ResponseEntity.ok();

        configPayloadSignatureService
                .sign(serializeConfigPayload(response))
                .ifPresent(signature -> {
                    builder.header("X-Config-Signature", signature);
                    builder.header("X-Config-Signature-Alg", configPayloadSignatureService.algorithmName());
                });

        return builder.body(response);
    }

    @PostMapping("/inspections/finalized")
    @Operation(
            summary = "Recebe payload finalizado de inspecao (v1)",
            description = "Operacao idempotente por X-Idempotency-Key.",
            responses = {
                    @ApiResponse(responseCode = "202", description = "Payload aceito para processamento"),
                    @ApiResponse(
                            responseCode = "400",
                            description = "Requisicao invalida",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    ),
                    @ApiResponse(
                            responseCode = "409",
                            description = "Conflito de idempotencia",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    )
            }
    )
    public ResponseEntity<InspectionFinalizedResponse> postInspectionFinalized(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @RequestHeader("X-Idempotency-Key") String idempotencyKey,
            @RequestHeader("X-Api-Version") String apiVersion,
            @Valid @RequestBody InspectionFinalizedRequest request
    ) {
        RequestContextValidator.requireApiVersion(apiVersion);
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        if (!org.springframework.util.StringUtils.hasText(idempotencyKey)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "IDEMPOTENCY_KEY_REQUIRED",
                    "X-Idempotency-Key e obrigatorio",
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
            description = "Retorna jobs atribuidos ao userId informado. Usa X-Actor-Id como identificador do vistoriador.",
            responses = {
                    @ApiResponse(responseCode = "200", description = "Lista de jobs retornada"),
                    @ApiResponse(
                            responseCode = "400",
                            description = "Contexto invalido",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    )
            }
    )
    public ResponseEntity<List<JobSummaryResponse>> getMobileJobs(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @RequestHeader("X-Api-Version") String apiVersion,
            @Parameter(description = "Filtro por status (ex: ACCEPTED, IN_EXECUTION). Padrao: ACCEPTED")
            @RequestParam(required = false) String status
    ) {
        RequestContextValidator.requireApiVersion(apiVersion);
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
                    "X-Actor-Id deve ser um ID numerico de usuario",
                    ErrorSeverity.ERROR,
                    "Informe o ID interno do usuario no cabecalho X-Actor-Id.",
                    "header: X-Actor-Id"
            );
        }
    }

    private String serializeConfigPayload(CheckinConfigResponse response) {
        try {
            return objectMapper.writeValueAsString(response);
        } catch (Exception exception) {
            return "";
        }
    }
}
