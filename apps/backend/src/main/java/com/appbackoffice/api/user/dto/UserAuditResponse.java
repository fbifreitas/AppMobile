package com.appbackoffice.api.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.List;

@Schema(name = "UserAuditResponse", description = "Lista de eventos de auditoria de usuarios")
public record UserAuditResponse(
        @Schema(description = "Eventos retornados") List<UserAuditEntryResponse> items,
        @Schema(description = "Quantidade retornada") int count,
        @Schema(description = "Timestamp de geracao") Instant generatedAt
) {
}