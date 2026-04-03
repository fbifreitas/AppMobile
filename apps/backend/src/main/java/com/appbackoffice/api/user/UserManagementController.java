package com.appbackoffice.api.user;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.contract.RequestContextValidator;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.security.RequiresTenantRole;
import com.appbackoffice.api.user.dto.ApprovalRequest;
import com.appbackoffice.api.user.dto.CreateUserRequest;
import com.appbackoffice.api.user.dto.ImportUsersRequest;
import com.appbackoffice.api.user.dto.ImportUsersResponse;
import com.appbackoffice.api.user.dto.UserAuditResponse;
import com.appbackoffice.api.user.dto.UserListResponse;
import com.appbackoffice.api.user.dto.UserResponse;
import com.appbackoffice.api.user.audit.UserAuditService;
import com.appbackoffice.api.user.entity.UserStatus;
import com.appbackoffice.api.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@Tag(name = "User Management", description = "Gestao de usuarios, aprovacoes e importacao")
public class UserManagementController {
    private final UserService userService;
        private final UserAuditService userAuditService;

        public UserManagementController(UserService userService, UserAuditService userAuditService) {
        this.userService = userService;
                this.userAuditService = userAuditService;
    }

    @GetMapping
        @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    @Operation(summary = "Listar todos os usuarios do tenant",
            description = "Lista todos os usuarios com filtro opcional por status.")
    @ApiResponse(responseCode = "200", content = @Content(mediaType = MediaType.APPLICATION_JSON_VALUE,
            schema = @Schema(implementation = UserListResponse.class)))
    public ResponseEntity<UserListResponse> listAllUsers(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @RequestParam(required = false) String status) {

        RequestContextValidator.requireCorrelationId(correlationId);

        List<UserResponse> users;
        if (status != null && !status.isBlank()) {
            try {
                UserStatus parsed = UserStatus.valueOf(status.toUpperCase());
                users = userService.findByStatus(tenantId, parsed).stream().map(UserResponse::from).toList();
            } catch (IllegalArgumentException e) {
                throw new ApiContractException(HttpStatus.BAD_REQUEST, "USER_INVALID_STATUS",
                        "Status invalido: " + status, ErrorSeverity.ERROR,
                        "Valores aceitos: AWAITING_APPROVAL, APPROVED, REJECTED", "status: " + status);
            }
        } else {
            users = userService.findAllUsers(tenantId).stream().map(UserResponse::from).toList();
        }

        return ResponseEntity.ok(new UserListResponse(users.size(), users));
    }

    @GetMapping("/pending")
        @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    @Operation(summary = "Listar usuarios aguardando aprovacao (mobile onboarding)")
    @ApiResponse(responseCode = "200", content = @Content(mediaType = MediaType.APPLICATION_JSON_VALUE,
            schema = @Schema(implementation = UserListResponse.class)))
    public ResponseEntity<UserListResponse> findPendingUsers(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId) {

        RequestContextValidator.requireCorrelationId(correlationId);

        List<UserResponse> users = userService.findPendingUsers(tenantId).stream().map(UserResponse::from).toList();
        return ResponseEntity.ok(new UserListResponse(users.size(), users));
    }

        @GetMapping("/audit")
        @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
        @Operation(summary = "Listar trilha de auditoria de usuarios",
                        description = "Consulta eventos recentes de acesso administrativo e mutacoes do modulo de usuarios.")
        @ApiResponse(responseCode = "200", content = @Content(mediaType = MediaType.APPLICATION_JSON_VALUE,
                        schema = @Schema(implementation = UserAuditResponse.class)))
        public ResponseEntity<UserAuditResponse> listUserAudit(
                        @RequestHeader("X-Tenant-Id") String tenantId,
                        @RequestHeader("X-Correlation-Id") String correlationId,
                        @RequestHeader("X-Actor-Id") String actorId,
                        @RequestParam(required = false) Long userId) {

                RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
                return ResponseEntity.ok(userAuditService.listAudit(tenantId, userId));
        }

    @GetMapping("/{userId}")
        @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.AUDITOR, MembershipRole.PLATFORM_ADMIN})
    @Operation(summary = "Obter detalhes de usuario")
    @ApiResponse(responseCode = "200", content = @Content(mediaType = MediaType.APPLICATION_JSON_VALUE,
            schema = @Schema(implementation = UserResponse.class)))
    @ApiResponse(responseCode = "404", description = "Usuario nao encontrado")
    public ResponseEntity<UserResponse> getUserById(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
            @PathVariable Long userId) {

        RequestContextValidator.requireCorrelationId(correlationId);
        return ResponseEntity.ok(UserResponse.from(userService.findUserById(tenantId, userId)));
    }

    @PostMapping
        @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.PLATFORM_ADMIN})
    @Operation(summary = "Criar usuario via backoffice web",
            description = "Admin cria usuario diretamente. Status inicial = APPROVED. Role obrigatorio.")
    @ApiResponse(responseCode = "201", content = @Content(mediaType = MediaType.APPLICATION_JSON_VALUE,
            schema = @Schema(implementation = UserResponse.class)))
    @ApiResponse(responseCode = "409", description = "Email ja cadastrado")
    public ResponseEntity<UserResponse> createUserFromWeb(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
                        @RequestHeader("X-Actor-Id") String actorId,
            @Valid @RequestBody CreateUserRequest request) {

                RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
                var user = userService.createFromWeb(tenantId, request, actorId, correlationId);
        return ResponseEntity.status(HttpStatus.CREATED).body(UserResponse.from(user));
    }

    @PostMapping("/import")
        @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.PLATFORM_ADMIN})
    @Operation(summary = "Importar usuarios em batch (AD/LDAP/CSV)",
            description = "Importa lista de usuarios de diretorio externo. Duplicados sao ignorados (idempotente).")
    @ApiResponse(responseCode = "200", content = @Content(mediaType = MediaType.APPLICATION_JSON_VALUE,
            schema = @Schema(implementation = ImportUsersResponse.class)))
    public ResponseEntity<ImportUsersResponse> importUsers(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
                        @RequestHeader("X-Actor-Id") String actorId,
            @Valid @RequestBody ImportUsersRequest request) {

                RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
                var result = userService.importFromExternalDirectory(tenantId, request.users(), actorId, correlationId);

        var importedDtos = result.imported().stream().map(UserResponse::from).toList();
        return ResponseEntity.ok(new ImportUsersResponse(
                request.users().size(),
                importedDtos.size(),
                result.skippedEmails().size(),
                importedDtos,
                result.skippedEmails()
        ));
    }

    @PostMapping("/{userId}/approve")
        @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.PLATFORM_ADMIN})
    @Operation(summary = "Aprovar usuario (mobile onboarding)")
    @ApiResponse(responseCode = "200", content = @Content(mediaType = MediaType.APPLICATION_JSON_VALUE,
            schema = @Schema(implementation = UserResponse.class)))
    public ResponseEntity<UserResponse> approveUser(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
                        @RequestHeader("X-Actor-Id") String actorId,
            @PathVariable Long userId,
            @RequestBody(required = false) ApprovalRequest request) {

                RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);
                return ResponseEntity.ok(UserResponse.from(userService.approveUser(tenantId, userId, actorId, correlationId)));
    }

    @PostMapping("/{userId}/reject")
        @RequiresTenantRole({MembershipRole.TENANT_ADMIN, MembershipRole.COORDINATOR, MembershipRole.PLATFORM_ADMIN})
    @Operation(summary = "Rejeitar usuario com motivo (mobile onboarding)")
    @ApiResponse(responseCode = "200", content = @Content(mediaType = MediaType.APPLICATION_JSON_VALUE,
            schema = @Schema(implementation = UserResponse.class)))
    public ResponseEntity<UserResponse> rejectUser(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @RequestHeader("X-Correlation-Id") String correlationId,
                        @RequestHeader("X-Actor-Id") String actorId,
            @PathVariable Long userId,
            @Valid @RequestBody ApprovalRequest request) {

                RequestContextValidator.requireFullContext(tenantId, correlationId, actorId);

        if (request == null || request.reason() == null || request.reason().isBlank()) {
            throw new ApiContractException(HttpStatus.BAD_REQUEST, "REJECTION_REASON_REQUIRED",
                    "Motivo da rejeicao e obrigatorio", ErrorSeverity.ERROR,
                    "Informe o campo 'reason' no corpo da requisicao", "field: reason");
        }

                return ResponseEntity.ok(UserResponse.from(userService.rejectUser(tenantId, userId, request.reason(), actorId, correlationId)));
    }
}
