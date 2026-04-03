package com.appbackoffice.api.user.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.identity.entity.Membership;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.identity.entity.MembershipStatus;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.user.audit.UserAuditAction;
import com.appbackoffice.api.user.audit.UserAuditService;
import com.appbackoffice.api.user.dto.CreateUserRequest;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserRole;
import com.appbackoffice.api.user.entity.UserSource;
import com.appbackoffice.api.user.entity.UserStatus;
import com.appbackoffice.api.user.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class UserService {
    private final UserRepository userRepository;
    private final TenantRepository tenantRepository;
    private final MembershipRepository membershipRepository;
    private final UserAuditService userAuditService;
    private final UserLifecycleService userLifecycleService;

    public UserService(UserRepository userRepository,
                       TenantRepository tenantRepository,
                       MembershipRepository membershipRepository,
                       UserAuditService userAuditService,
                       UserLifecycleService userLifecycleService) {
        this.userRepository = userRepository;
        this.tenantRepository = tenantRepository;
        this.membershipRepository = membershipRepository;
        this.userAuditService = userAuditService;
        this.userLifecycleService = userLifecycleService;
    }

    // --- Fluxo mobile onboarding (status inicial = AWAITING_APPROVAL) ---

    public User createFromMobileOnboarding(String tenantId, String email, String nome, String tipo, String cpf, String cnpj) {
        checkEmailConflict(tenantId, email);
        User user = new User(tenantId, email, nome, tipo);
        user.setCpf(cpf);
        user.setCnpj(cnpj);
        User saved = userRepository.save(user);
        userLifecycleService.initializePending(saved);
        upsertMembership(saved, MembershipRole.FIELD_OPERATOR, MembershipStatus.SUSPENDED);
        return saved;
    }

    public User createFromMobileOnboarding(
            String tenantId,
            String email,
            String nome,
            String tipo,
            String cpf,
            String cnpj,
            String actorId,
            String correlationId
    ) {
        User saved = createFromMobileOnboarding(tenantId, email, nome, tipo, cpf, cnpj);
        userAuditService.record(
                saved,
                actorId,
                correlationId,
                UserAuditAction.USER_ONBOARDING_SUBMITTED,
                "source=MOBILE_ONBOARDING"
        );
        return saved;
    }

    public List<User> findPendingUsers(String tenantId) {
        return userRepository.findByTenantIdAndStatus(tenantId, UserStatus.AWAITING_APPROVAL)
                .stream()
                .map(this::applyEffectiveRoleFromMembership)
                .toList();
    }

    public User approveUser(String tenantId, Long userId) {
        User user = findUserById(tenantId, userId);

        if (user.getStatus() != UserStatus.AWAITING_APPROVAL) {
            throw new ApiContractException(HttpStatus.CONFLICT,
                    "USER_APPROVAL_INVALID_STATE",
                    "Usuário não está aguardando aprovação",
                    ErrorSeverity.ERROR,
                    "Apenas usuários em estado AWAITING_APPROVAL podem ser aprovados",
                    "status: " + user.getStatus());
        }

        user.setStatus(UserStatus.APPROVED);
        user.setApprovedAt(Instant.now());
        User saved = userRepository.save(user);
        userLifecycleService.markApproved(saved);
        upsertMembership(saved, toMembershipRole(resolveEffectiveRole(saved)), MembershipStatus.ACTIVE);
        return saved;
    }

    public User approveUser(String tenantId, Long userId, String actorId, String correlationId) {
        User approved = approveUser(tenantId, userId);
        userAuditService.record(
                approved,
                actorId,
                correlationId,
                UserAuditAction.USER_APPROVED,
                "status=" + approved.getStatus()
        );
        return approved;
    }

    public User rejectUser(String tenantId, Long userId, String reason) {
        User user = findUserById(tenantId, userId);

        if (user.getStatus() != UserStatus.AWAITING_APPROVAL) {
            throw new ApiContractException(HttpStatus.CONFLICT,
                    "USER_REJECTION_INVALID_STATE",
                    "Usuário não está aguardando aprovação",
                    ErrorSeverity.ERROR,
                    "Apenas usuários em estado AWAITING_APPROVAL podem ser rejeitados",
                    "status: " + user.getStatus());
        }

        user.setStatus(UserStatus.REJECTED);
        user.setRejectedAt(Instant.now());
        user.setRejectionReason(reason);
        User saved = userRepository.save(user);
        userLifecycleService.markRejected(saved, reason);
        upsertMembership(saved, toMembershipRole(resolveEffectiveRole(saved)), MembershipStatus.REVOKED);
        return saved;
    }

    public User rejectUser(String tenantId, Long userId, String reason, String actorId, String correlationId) {
        User rejected = rejectUser(tenantId, userId, reason);
        userAuditService.record(
                rejected,
                actorId,
                correlationId,
                UserAuditAction.USER_REJECTED,
                "reason=" + reason
        );
        return rejected;
    }

    // --- Fluxo web backoffice (status inicial = APPROVED) ---

    public User createFromWeb(String tenantId, CreateUserRequest req) {
        checkEmailConflict(tenantId, req.email());
        UserRole role = parseRole(req.role());
        User user = new User(tenantId, req.email(), req.nome(), req.tipo(), role, UserSource.WEB_CREATED);
        user.setCpf(req.cpf());
        user.setCnpj(req.cnpj());
        user.setExternalId(req.externalId());
        User saved = userRepository.save(user);
        userLifecycleService.initializeApproved(saved);
        upsertMembership(saved, toMembershipRole(role), MembershipStatus.ACTIVE);
        return saved;
    }

    public User createFromWeb(String tenantId, CreateUserRequest req, String actorId, String correlationId) {
        User saved = createFromWeb(tenantId, req);
        userAuditService.record(
                saved,
                actorId,
                correlationId,
                UserAuditAction.USER_CREATED_WEB,
                "role=" + req.role() + ", source=WEB_CREATED"
        );
        return saved;
    }

    // --- Fluxo importação AD/LDAP (batch, status = APPROVED) ---

    public record ImportResult(List<User> imported, List<String> skippedEmails) {}

    public ImportResult importFromExternalDirectory(String tenantId, List<CreateUserRequest> users) {
        List<User> imported = new ArrayList<>();
        List<String> skipped = new ArrayList<>();

        for (CreateUserRequest req : users) {
            boolean emailExists = userRepository.findByTenantIdAndEmail(tenantId, req.email()).isPresent();
            if (emailExists) {
                skipped.add(req.email());
                continue;
            }

            if (req.externalId() != null && !req.externalId().isBlank()) {
                boolean idExists = userRepository.findByTenantIdAndExternalId(tenantId, req.externalId()).isPresent();
                if (idExists) {
                    skipped.add(req.email() + " (externalId duplicate)");
                    continue;
                }
            }

            UserRole role = parseRole(req.role());
            User user = new User(tenantId, req.email(), req.nome(), req.tipo(), role, UserSource.AD_IMPORT);
            user.setCpf(req.cpf());
            user.setCnpj(req.cnpj());
            user.setExternalId(req.externalId());
            User saved = userRepository.save(user);
            userLifecycleService.initializeApproved(saved);
            upsertMembership(saved, toMembershipRole(role), MembershipStatus.ACTIVE);
            imported.add(saved);
        }

        return new ImportResult(imported, skipped);
    }

    public ImportResult importFromExternalDirectory(
            String tenantId,
            List<CreateUserRequest> users,
            String actorId,
            String correlationId
    ) {
        ImportResult result = importFromExternalDirectory(tenantId, users);
        for (User importedUser : result.imported()) {
            userAuditService.record(
                    importedUser,
                    actorId,
                    correlationId,
                    UserAuditAction.USER_IMPORTED_AD,
                    "source=" + importedUser.getSource() + ", externalId=" + importedUser.getExternalId()
            );
        }
        return result;
    }

    // --- Consultas gerais ---

    public List<User> findAllUsers(String tenantId) {
        return userRepository.findByTenantId(tenantId)
            .stream()
            .map(this::applyEffectiveRoleFromMembership)
            .toList();
    }

    public List<User> findByStatus(String tenantId, UserStatus status) {
        return userRepository.findByTenantIdAndStatus(tenantId, status)
            .stream()
            .map(this::applyEffectiveRoleFromMembership)
            .toList();
    }

    public User findUserById(String tenantId, Long userId) {
        User user = userRepository.findByTenantIdAndId(tenantId, userId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND, "USER_NOT_FOUND",
                        "Usuário não encontrado", ErrorSeverity.ERROR,
                        "Verifique o ID do usuário e tente novamente",
                        "userId: " + userId));

        return applyEffectiveRoleFromMembership(user);
    }

    // --- helpers ---

    private void checkEmailConflict(String tenantId, String email) {
        userRepository.findByTenantIdAndEmail(tenantId, email).ifPresent(u -> {
            throw new ApiContractException(HttpStatus.CONFLICT,
                    "USER_ALREADY_EXISTS",
                    "Email já cadastrado neste tenant",
                    ErrorSeverity.ERROR,
                    "Use outro email ou contate a administração",
                    "email: " + email);
        });
    }

    private UserRole parseRole(String roleName) {
        if (roleName == null || roleName.isBlank()) {
            throw new ApiContractException(HttpStatus.BAD_REQUEST,
                    "USER_INVALID_ROLE",
                    "Role inválida: " + roleName,
                    ErrorSeverity.ERROR,
                    "Valores aceitos: ADMIN, OPERATOR, FIELD_AGENT, VIEWER",
                    "role: " + roleName);
        }

        try {
            return UserRole.valueOf(roleName.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ApiContractException(HttpStatus.BAD_REQUEST,
                    "USER_INVALID_ROLE",
                    "Role inválida: " + roleName,
                    ErrorSeverity.ERROR,
                    "Valores aceitos: ADMIN, OPERATOR, FIELD_AGENT, VIEWER",
                    "role: " + roleName);
        }
    }

    private MembershipRole toMembershipRole(UserRole role) {
        if (role == null) {
            return MembershipRole.FIELD_OPERATOR;
        }

        return switch (role) {
            case ADMIN -> MembershipRole.TENANT_ADMIN;
            case OPERATOR -> MembershipRole.OPERATOR;
            case FIELD_AGENT -> MembershipRole.FIELD_OPERATOR;
            case VIEWER -> MembershipRole.AUDITOR;
        };
    }

    private UserRole toUserRole(MembershipRole membershipRole) {
        if (membershipRole == null) {
            return null;
        }

        return switch (membershipRole) {
            case TENANT_ADMIN -> UserRole.ADMIN;
            case OPERATOR, COORDINATOR, REGIONAL_COORD, PLATFORM_ADMIN -> UserRole.OPERATOR;
            case AUDITOR -> UserRole.VIEWER;
            case FIELD_OPERATOR -> UserRole.FIELD_AGENT;
        };
    }

    private User applyEffectiveRoleFromMembership(User user) {
        user.setRole(resolveEffectiveRole(user));
        return user;
    }

    private UserRole resolveEffectiveRole(User user) {
        return toUserRole(ensureMembership(user).getRole());
    }

    private Membership ensureMembership(User user) {
        return membershipRepository.findByUser_IdAndTenant_Id(user.getId(), user.getTenantId())
                .orElseGet(() -> backfillLegacyMembership(user));
    }

    private Membership backfillLegacyMembership(User user) {
        MembershipRole role = toMembershipRole(user.getRole());
        MembershipStatus status = switch (user.getStatus()) {
            case APPROVED -> MembershipStatus.ACTIVE;
            case REJECTED -> MembershipStatus.REVOKED;
            case AWAITING_APPROVAL -> MembershipStatus.SUSPENDED;
        };
        upsertMembership(user, role, status);

        return membershipRepository.findByUser_IdAndTenant_Id(user.getId(), user.getTenantId())
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "USER_MEMBERSHIP_BACKFILL_FAILED",
                        "Nao foi possivel criar membership legado do usuario",
                        ErrorSeverity.ERROR,
                        "Tente novamente ou contate suporte",
                        "userId: " + user.getId() + ", tenantId: " + user.getTenantId()));
    }

    private void upsertMembership(User user, MembershipRole role, MembershipStatus status) {
        Tenant tenant = resolveOrCreateTenant(user.getTenantId());
        Membership membership = membershipRepository
                .findByUser_IdAndTenant_Id(user.getId(), user.getTenantId())
                .orElseGet(() -> new Membership(user, tenant, null, role, status));

        membership.setUser(user);
        membership.setTenant(tenant);
        membership.setRole(role);
        membership.setStatus(status);
        membership.setRevokedAt(status == MembershipStatus.REVOKED ? Instant.now() : null);

        membershipRepository.save(membership);
    }

    private Tenant resolveOrCreateTenant(String tenantId) {
        return tenantRepository.findById(tenantId)
                .orElseGet(() -> tenantRepository.save(new Tenant(tenantId, tenantId, tenantId, TenantStatus.ACTIVE)));
    }
}
