package com.appbackoffice.api.mobile;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.CanonicalErrorResponse;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.mobile.dto.CheckinConfigResponse;
import com.appbackoffice.api.mobile.dto.InspectionFinalizedRequest;
import com.appbackoffice.api.mobile.dto.InspectionFinalizedResponse;
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

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@Validated
@RequestMapping("/api/mobile")
@Tag(name = "Mobile v1", description = "Contratos críticos do AppMobile (v1)")
public class MobileApiController {

    private final Map<String, InspectionFinalizedResponse> idempotencyStore = new ConcurrentHashMap<>();

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

        Map<String, Object> step1 = Map.of(
                "tipos", List.of("Urbano", "Rural", "Comercial", "Industrial"),
                "subtiposPorTipo", Map.of("Urbano", List.of("Apartamento", "Casa", "Sobrado", "Terreno"))
        );
        Map<String, Object> step2 = Map.of(
                "camposFotos", List.of("fachada", "logradouro"),
                "gruposOpcoes", List.of("infraestrutura_servicos")
        );

        CheckinConfigResponse response = new CheckinConfigResponse(
                "v1",
                step1,
                step2,
                List.of(
                        "Compatibilidade v1: campos existentes não serão removidos/renomeados sem nova major.",
                        "Tenant e correlationId são obrigatórios para rastreabilidade ponta a ponta."
                )
        );
        return ResponseEntity.ok(response);
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

        String scopedKey = tenantId + ":" + idempotencyKey.trim();
        InspectionFinalizedResponse existing = idempotencyStore.get(scopedKey);
        if (existing != null) {
            return ResponseEntity.status(HttpStatus.ACCEPTED)
                    .body(new InspectionFinalizedResponse(existing.protocolId(), existing.receivedAt(), existing.status(), true));
        }

        InspectionFinalizedResponse created = new InspectionFinalizedResponse(
                "proto-" + UUID.randomUUID(),
                Instant.now(),
                "accepted",
                false
        );
        idempotencyStore.put(scopedKey, created);
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(created);
    }

}
