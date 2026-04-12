package com.appbackoffice.api.auth.dto;

import java.util.List;

public record AuthMeResponse(
        Long userId,
        String tenantId,
        String email,
        String nome,
        String tipo,
        String cpf,
        String cnpj,
        String userStatus,
        String membershipRole,
        String membershipStatus,
        List<String> permissions
) {
}
