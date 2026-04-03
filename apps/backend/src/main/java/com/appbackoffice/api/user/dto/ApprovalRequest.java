package com.appbackoffice.api.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(name = "ApprovalRequest", description = "Requisição de aprovação ou rejeição de usuário")
public record ApprovalRequest(
        @NotBlank(message = "action é obrigatório")
        @Schema(example = "approve", description = "Ação: 'approve' ou 'reject'") String action,
        @Schema(example = "Documentação completa e validada", description = "Motivo (opcional para approve, obrigatório para reject)") String reason
) {
}
