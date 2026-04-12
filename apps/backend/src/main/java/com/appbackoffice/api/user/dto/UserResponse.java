package com.appbackoffice.api.user.dto;

import com.appbackoffice.api.user.entity.User;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.time.LocalDate;

@Schema(name = "UserResponse", description = "Resposta com detalhes de usuário")
public record UserResponse(
        @Schema(example = "1") Long id,
        @Schema(example = "tenant-a") String tenantId,
        @Schema(example = "joao@example.com") String email,
        @Schema(example = "João Silva") String nome,
        @Schema(example = "PJ") String tipo,
        @Schema(example = "12345678901") String cpf,
        @Schema(example = "12345678901234") String cnpj,
        @Schema(example = "1990-05-20") LocalDate birthDate,
        @Schema(example = "5511999999999") String phone,
        @Schema(example = "APPROVED") String status,
        @Schema(example = "APPROVED", description = "Estado do fluxo de lifecycle separado") String lifecycleStatus,
        @Schema(example = "FIELD_AGENT", description = "Role do usuário") String role,
        @Schema(example = "MOBILE_ONBOARDING", description = "Origem do cadastro") String source,
        @Schema(example = "ad-uuid-001", description = "ID externo (AD/LDAP)") String externalId,
        @Schema(example = "2026-04-01T10:15:30Z") Instant createdAt,
        @Schema(example = "2026-04-01T11:30:00Z") Instant approvedAt,
        @Schema(example = "2026-04-01T12:45:00Z") Instant rejectedAt,
        @Schema(description = "Motivo da rejeição (se rejeitado)") String rejectionReason
) {
    public static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getTenantId(),
                user.getEmail(),
                user.getNome(),
                user.getTipo(),
                user.getCpf(),
                user.getCnpj(),
                user.getBirthDate(),
                user.getPhone(),
                user.getStatus().toString(),
                user.getLifecycle() != null ? user.getLifecycle().getStatus().toString() : null,
                user.getRole() != null ? user.getRole().toString() : null,
                user.getSource() != null ? user.getSource().toString() : null,
                user.getExternalId(),
                user.getCreatedAt(),
                user.getApprovedAt(),
                user.getRejectedAt(),
                user.getRejectionReason()
        );
    }
}
