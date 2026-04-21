package com.appbackoffice.api.mobile;

import com.appbackoffice.api.auth.dto.AuthMeResponse;
import com.appbackoffice.api.auth.service.AuthService;
import com.appbackoffice.api.config.ConfigPayloadSignatureService;
import com.appbackoffice.api.config.ConfigPackageService;
import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.CanonicalErrorResponse;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.intelligence.dto.ExecutionPlanResponse;
import com.appbackoffice.api.intelligence.service.IntelligenceBackofficeService;
import com.appbackoffice.api.job.dto.JobSummaryResponse;
import com.appbackoffice.api.job.service.JobClientAbsentEvidenceService.ClientAbsentEvidenceCommand;
import com.appbackoffice.api.job.service.JobService;
import com.appbackoffice.api.mobile.dto.CheckinConfigResponse;
import com.appbackoffice.api.mobile.dto.InspectionFinalizedRequest;
import com.appbackoffice.api.mobile.dto.InspectionFinalizedResponse;
import com.appbackoffice.api.mobile.dto.JobClientAbsentRequest;
import com.appbackoffice.api.config.dto.ConfigPackageApplicationStatusRequest;
import com.appbackoffice.api.config.dto.ConfigPackageApplicationStatusResponse;
import com.appbackoffice.api.mobile.service.InspectionSubmissionService;
import com.appbackoffice.api.mobile.service.MobileCheckinConfigService;
import com.appbackoffice.api.mobile.service.MobileJobQueryService;
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
import org.springframework.web.bind.annotation.PathVariable;
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

    private final AuthService authService;
    private final JobService jobService;
    private final InspectionSubmissionService inspectionSubmissionService;
    private final MobileCheckinConfigService mobileCheckinConfigService;
    private final ConfigPayloadSignatureService configPayloadSignatureService;
    private final ConfigPackageService configPackageService;
    private final IntelligenceBackofficeService intelligenceBackofficeService;
    private final MobileJobQueryService mobileJobQueryService;
    private final ObjectMapper objectMapper;

    public MobileApiController(AuthService authService,
                               JobService jobService,
                               InspectionSubmissionService inspectionSubmissionService,
                               MobileCheckinConfigService mobileCheckinConfigService,
                               ConfigPayloadSignatureService configPayloadSignatureService,
                               ConfigPackageService configPackageService,
                               IntelligenceBackofficeService intelligenceBackofficeService,
                               MobileJobQueryService mobileJobQueryService,
                               ObjectMapper objectMapper) {
        this.authService = authService;
        this.jobService = jobService;
        this.inspectionSubmissionService = inspectionSubmissionService;
        this.mobileCheckinConfigService = mobileCheckinConfigService;
        this.configPayloadSignatureService = configPayloadSignatureService;
        this.configPackageService = configPackageService;
        this.intelligenceBackofficeService = intelligenceBackofficeService;
        this.mobileJobQueryService = mobileJobQueryService;
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
            @Parameter(description = "Neutral alias for tipoImovel")
            @RequestParam(required = false) String assetType,
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @RequestHeader("X-Api-Version") String apiVersion,
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader
    ) {
        RequestContextValidator.requireApiVersion(apiVersion);
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        validateMobileBearerIfPresent(authorizationHeader, tenantId, actorId);

        String resolvedAssetType = assetType != null && !assetType.isBlank() ? assetType : tipoImovel;
        CheckinConfigResponse response = mobileCheckinConfigService.resolve(tenantId, actorId, resolvedAssetType);
        ResponseEntity.BodyBuilder builder = ResponseEntity.ok();

        configPayloadSignatureService
                .sign(serializeConfigPayload(response))
                .ifPresent(signature -> {
                    builder.header("X-Config-Signature", signature);
                    builder.header("X-Config-Signature-Alg", configPayloadSignatureService.algorithmName());
                });

        return builder.body(response);
    }

    @PostMapping("/config-packages/application-status")
    @Operation(
            summary = "Registra ACK/NACK de aplicacao de pacote operacional (v1)",
            description = "Permite ao backoffice acompanhar quais dispositivos aplicaram ou rejeitaram a configuracao remota.",
            responses = {
                    @ApiResponse(responseCode = "202", description = "Status registrado"),
                    @ApiResponse(
                            responseCode = "400",
                            description = "Requisicao invalida",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    )
            }
    )
    public ResponseEntity<ConfigPackageApplicationStatusResponse> postConfigPackageApplicationStatus(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @RequestHeader("X-Api-Version") String apiVersion,
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @Valid @RequestBody ConfigPackageApplicationStatusRequest request
    ) {
        RequestContextValidator.requireApiVersion(apiVersion);
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        validateMobileBearerIfPresent(authorizationHeader, tenantId, actorId);

        ConfigPackageApplicationStatusResponse response = configPackageService.recordApplicationStatus(
                tenantId,
                actorId,
                request
        );
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(response);
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
            @RequestHeader("X-Request-Timestamp") String requestTimestamp,
            @RequestHeader("X-Request-Nonce") String requestNonce,
            @RequestHeader("X-Api-Version") String apiVersion,
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @Valid @RequestBody InspectionFinalizedRequest request
    ) {
        RequestContextValidator.requireApiVersion(apiVersion);
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        RequestContextValidator.requireIdempotencyKey(idempotencyKey);
        RequestContextValidator.requireProtectedWriteHeaders(requestTimestamp, requestNonce);
        validateMobileBearerIfPresent(authorizationHeader, tenantId, actorId);

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
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @Parameter(description = "Filtro por status (ex: ACCEPTED, IN_EXECUTION). Padrao: ACCEPTED")
            @RequestParam(required = false) String status
    ) {
        RequestContextValidator.requireApiVersion(apiVersion);
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        Long userId = parseUserId(actorId);
        validateMobileBearer(authorizationHeader, tenantId, userId);
        return ResponseEntity.ok(mobileJobQueryService.listJobs(tenantId, userId, status));
    }

    @PostMapping("/jobs/{jobId}/client-absent")
    @Operation(
            summary = "Sinaliza cliente ausente no check-in etapa 1",
            description = "Move o job para aguardando agendamento e registra a tratativa para o backoffice.",
            responses = {
                    @ApiResponse(responseCode = "200", description = "Job atualizado com sucesso"),
                    @ApiResponse(
                            responseCode = "400",
                            description = "Contexto invalido",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    ),
                    @ApiResponse(
                            responseCode = "401",
                            description = "Token invalido ou fora de contexto",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    ),
                    @ApiResponse(
                            responseCode = "409",
                            description = "Estado atual do job nao permite mover para aguardando agendamento",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    )
            }
    )
    public ResponseEntity<JobSummaryResponse> postClientAbsent(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @RequestHeader("X-Api-Version") String apiVersion,
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @PathVariable Long jobId,
            @RequestBody(required = false) JobClientAbsentRequest request
    ) {
        RequestContextValidator.requireApiVersion(apiVersion);
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        Long userId = parseUserId(actorId);
        validateMobileBearer(authorizationHeader, tenantId, userId);

        String reason = request != null ? request.reason() : null;
        String responderName = request != null ? request.responderName() : null;
        ClientAbsentEvidenceCommand evidence = request != null && request.evidence() != null
                ? new ClientAbsentEvidenceCommand(
                request.evidence().fileName(),
                request.evidence().contentType(),
                request.evidence().imageBase64(),
                request.evidence().capturedAt(),
                request.evidence().latitude(),
                request.evidence().longitude(),
                request.evidence().accuracy()
        )
                : null;
        return ResponseEntity.ok(
                jobService.requestSchedulingAfterClientAbsent(tenantId, jobId, actorId, reason, responderName, evidence)
        );
    }

    @GetMapping("/jobs/{jobId}/execution-plan")
    @Operation(
            summary = "Retorna o ultimo execution plan publicado para o job (v1)",
            description = "Canal inicial para o smart app consumir hints operacionais gerados pela plataforma.",
            responses = {
                    @ApiResponse(responseCode = "200", description = "Execution plan retornado com sucesso"),
                    @ApiResponse(
                            responseCode = "404",
                            description = "Execution plan nao encontrado",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = CanonicalErrorResponse.class))
                    )
            }
    )
    public ResponseEntity<ExecutionPlanResponse> getExecutionPlanForJob(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestHeader("X-Actor-Id") String actorId,
            @RequestHeader("X-Api-Version") String apiVersion,
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @PathVariable Long jobId
    ) {
        RequestContextValidator.requireApiVersion(apiVersion);
        RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
        Long userId = parseUserId(actorId);
        validateMobileBearer(authorizationHeader, tenantId, userId);
        return ResponseEntity.ok(intelligenceBackofficeService.getLatestExecutionPlanForJob(tenantId, jobId));
    }

    private void validateMobileBearerIfPresent(String authorizationHeader, String tenantId, String actorId) {
        if (authorizationHeader == null || authorizationHeader.isBlank()) {
            return;
        }
        validateMobileBearer(authorizationHeader, tenantId, parseUserId(actorId));
    }

    private void validateMobileBearer(String authorizationHeader, String tenantId, Long userId) {
        AuthMeResponse session = authService.me(extractBearer(authorizationHeader));
        if (!tenantId.equals(session.tenantId()) || !userId.equals(session.userId())) {
            throw new ApiContractException(
                    HttpStatus.UNAUTHORIZED,
                    "AUTH_CONTEXT_MISMATCH",
                    "Token nao corresponde ao contexto mobile informado",
                    ErrorSeverity.ERROR,
                    "Refaca login e envie X-Tenant-Id e X-Actor-Id da sessao autenticada.",
                    "tenantId=" + tenantId + ", actorId=" + userId
            );
        }
    }

    private String extractBearer(String authorizationHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            throw new ApiContractException(
                    HttpStatus.UNAUTHORIZED,
                    "AUTH_INVALID_TOKEN",
                    "Token invalido ou expirado",
                    ErrorSeverity.ERROR,
                    "Envie Authorization: Bearer <token>.",
                    null
            );
        }
        return authorizationHeader.substring("Bearer ".length());
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
