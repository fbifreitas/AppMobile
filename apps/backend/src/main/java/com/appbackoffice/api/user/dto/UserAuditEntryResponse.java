package com.appbackoffice.api.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;

@Schema(name = "UserAuditEntryResponse", description = "Evento de auditoria do ciclo de vida de usuario")
public record UserAuditEntryResponse(
        @Schema(example = "user-audit-123") String id,
        @Schema(example = "42") Long userId,
        @Schema(example = "joao@example.com") String userEmail,
        @Schema(example = "backoffice-admin") String actorId,
        @Schema(example = "USER_APPROVED") String action,
        @Schema(example = "corr-123") String correlationId,
        @Schema(example = "reason=Documentacao incompleta") String details,
        @Schema(example = "2026-04-02T14:30:00Z") Instant createdAt
) {
}