package com.appbackoffice.api.platform.service;

import com.appbackoffice.api.auth.entity.UserCredentialEntity;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.identity.entity.Membership;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.identity.entity.MembershipStatus;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.platform.dto.TenantAdminHandoffResponse;
import com.appbackoffice.api.platform.dto.TenantApplicationResponse;
import com.appbackoffice.api.platform.dto.TenantLicenseResponse;
import com.appbackoffice.api.platform.dto.TenantPlatformListResponse;
import com.appbackoffice.api.platform.dto.TenantPlatformSummaryResponse;
import com.appbackoffice.api.platform.dto.UpsertTenantAdminHandoffRequest;
import com.appbackoffice.api.platform.dto.UpsertTenantApplicationRequest;
import com.appbackoffice.api.platform.dto.UpsertTenantLicenseRequest;
import com.appbackoffice.api.platform.entity.LicenseModel;
import com.appbackoffice.api.platform.entity.TenantApplicationEntity;
import com.appbackoffice.api.platform.entity.TenantApplicationStatus;
import com.appbackoffice.api.platform.entity.TenantLicenseEntity;
import com.appbackoffice.api.platform.repository.TenantApplicationRepository;
import com.appbackoffice.api.platform.repository.TenantLicenseRepository;
import com.appbackoffice.api.user.dto.CreateUserRequest;
import com.appbackoffice.api.user.dto.UserResponse;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserRole;
import com.appbackoffice.api.user.repository.UserRepository;
import com.appbackoffice.api.user.service.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class PlatformTenantService {

    private final TenantRepository tenantRepository;
    private final TenantApplicationRepository tenantApplicationRepository;
    private final TenantLicenseRepository tenantLicenseRepository;
    private final TenantLicensingService tenantLicensingService;
    private final MembershipRepository membershipRepository;
    private final UserRepository userRepository;
    private final UserCredentialRepository userCredentialRepository;
    private final UserService userService;
    private final PasswordEncoder passwordEncoder;

    public PlatformTenantService(TenantRepository tenantRepository,
                                 TenantApplicationRepository tenantApplicationRepository,
                                 TenantLicenseRepository tenantLicenseRepository,
                                 TenantLicensingService tenantLicensingService,
                                 MembershipRepository membershipRepository,
                                 UserRepository userRepository,
                                 UserCredentialRepository userCredentialRepository,
                                 UserService userService,
                                 PasswordEncoder passwordEncoder) {
        this.tenantRepository = tenantRepository;
        this.tenantApplicationRepository = tenantApplicationRepository;
        this.tenantLicenseRepository = tenantLicenseRepository;
        this.tenantLicensingService = tenantLicensingService;
        this.membershipRepository = membershipRepository;
        this.userRepository = userRepository;
        this.userCredentialRepository = userCredentialRepository;
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public TenantPlatformListResponse listTenants(String q, String status) {
        List<Tenant> tenants = tenantRepository.findAll().stream()
                .filter(tenant -> matchesStatus(tenant, status))
                .filter(tenant -> matchesQuery(tenant, q))
                .toList();

        List<String> tenantIds = tenants.stream().map(Tenant::getId).toList();
        Map<String, TenantApplicationEntity> applications = tenantApplicationRepository.findByTenantIdIn(tenantIds).stream()
                .collect(Collectors.toMap(TenantApplicationEntity::getTenantId, Function.identity()));
        Map<String, TenantLicenseEntity> licenses = tenantLicenseRepository.findByTenantIdIn(tenantIds).stream()
                .collect(Collectors.toMap(TenantLicenseEntity::getTenantId, Function.identity()));

        List<TenantPlatformSummaryResponse> items = tenants.stream()
                .map(tenant -> new TenantPlatformSummaryResponse(
                        tenant.getId(),
                        tenant.getSlug(),
                        tenant.getDisplayName(),
                        tenant.getStatus().name(),
                        toApplicationResponse(applications.get(tenant.getId())),
                        tenantLicensingService.toResponse(tenant.getId(), licenses.get(tenant.getId()))
                ))
                .toList();

        return new TenantPlatformListResponse(Instant.now(), items.size(), items);
    }

    @Transactional(readOnly = true)
    public TenantApplicationResponse getApplication(String tenantId) {
        requireTenant(tenantId);
        return toApplicationResponse(tenantApplicationRepository.findByTenantId(tenantId).orElse(null));
    }

    @Transactional
    public TenantApplicationResponse upsertApplication(String tenantId, UpsertTenantApplicationRequest request) {
        requireTenant(tenantId);
        TenantApplicationEntity entity = tenantApplicationRepository.findByTenantId(tenantId)
                .orElseGet(TenantApplicationEntity::new);
        entity.setTenantId(tenantId);
        entity.setAppCode(trim(request.appCode()));
        entity.setBrandName(trim(request.brandName()));
        entity.setDisplayName(trim(request.displayName()));
        entity.setApplicationId(trim(request.applicationId()));
        entity.setBundleId(trim(request.bundleId()));
        entity.setFirebaseAppId(trimToNull(request.firebaseAppId()));
        entity.setDistributionChannel(trimToNull(request.distributionChannel()));
        entity.setDistributionGroup(trimToNull(request.distributionGroup()));
        entity.setStatus(parseApplicationStatus(request.status()));
        return toApplicationResponse(tenantApplicationRepository.save(entity));
    }

    @Transactional(readOnly = true)
    public TenantLicenseResponse getLicense(String tenantId) {
        requireTenant(tenantId);
        return tenantLicensingService.toResponse(tenantId, tenantLicenseRepository.findByTenantId(tenantId).orElse(null));
    }

    @Transactional
    public TenantLicenseResponse upsertLicense(String tenantId, UpsertTenantLicenseRequest request) {
        requireTenant(tenantId);
        if (request.warningSeats() > request.contractedSeats()) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "LICENSE_INVALID_WARNING_THRESHOLD",
                    "warningSeats nao pode ser maior que contractedSeats",
                    ErrorSeverity.ERROR,
                    "Ajuste os limites de licenca e tente novamente.",
                    "tenantId=" + tenantId
            );
        }

        TenantLicenseEntity entity = tenantLicenseRepository.findByTenantId(tenantId)
                .orElseGet(TenantLicenseEntity::new);
        entity.setTenantId(tenantId);
        entity.setLicenseModel(parseLicenseModel(request.licenseModel()));
        entity.setContractedSeats(request.contractedSeats());
        entity.setWarningSeats(request.warningSeats());
        entity.setHardLimitEnforced(request.hardLimitEnforced());
        entity = tenantLicenseRepository.save(entity);
        return tenantLicensingService.toResponse(tenantId, entity);
    }

    @Transactional(readOnly = true)
    public TenantAdminHandoffResponse getAdminHandoff(String tenantId) {
        requireTenant(tenantId);
        return toAdminHandoffResponse(tenantId, null);
    }

    @Transactional
    public TenantAdminHandoffResponse upsertAdminHandoff(String tenantId, UpsertTenantAdminHandoffRequest request) {
        requireTenant(tenantId);

        User adminUser = userRepository.findByTenantIdAndEmail(tenantId, request.email())
                .map(existing -> ensureAdminUser(tenantId, existing, request))
                .orElseGet(() -> userService.createFromWeb(
                        tenantId,
                        new CreateUserRequest(
                                request.email(),
                                request.nome(),
                                request.tipo(),
                                request.cpf(),
                                request.cnpj(),
                                UserRole.ADMIN.name(),
                                request.externalId()
                        )
                ));

        UserCredentialEntity credential = userCredentialRepository.findByTenantIdAndUserId(tenantId, adminUser.getId())
                .orElseGet(UserCredentialEntity::new);
        credential.setTenantId(tenantId);
        credential.setUserId(adminUser.getId());
        credential.setPasswordHash(passwordEncoder.encode(request.temporaryPassword()));
        userCredentialRepository.save(credential);

        return toAdminHandoffResponse(tenantId, request.temporaryPassword());
    }

    private Tenant requireTenant(String tenantId) {
        return tenantRepository.findById(tenantId).orElseThrow(() -> new ApiContractException(
                HttpStatus.NOT_FOUND,
                "TENANT_NOT_FOUND",
                "Tenant nao encontrado",
                ErrorSeverity.ERROR,
                "Use um tenant valido antes de continuar.",
                "tenantId=" + tenantId
        ));
    }

    private boolean matchesStatus(Tenant tenant, String status) {
        if (!StringUtils.hasText(status)) {
            return true;
        }
        return tenant.getStatus().name().equalsIgnoreCase(status.trim());
    }

    private boolean matchesQuery(Tenant tenant, String q) {
        if (!StringUtils.hasText(q)) {
            return true;
        }
        String normalized = q.trim().toLowerCase(Locale.ROOT);
        return tenant.getId().toLowerCase(Locale.ROOT).contains(normalized)
                || tenant.getSlug().toLowerCase(Locale.ROOT).contains(normalized)
                || tenant.getDisplayName().toLowerCase(Locale.ROOT).contains(normalized);
    }

    private TenantApplicationResponse toApplicationResponse(TenantApplicationEntity entity) {
        if (entity == null) {
            return null;
        }
        return new TenantApplicationResponse(
                entity.getTenantId(),
                entity.getAppCode(),
                entity.getBrandName(),
                entity.getDisplayName(),
                entity.getApplicationId(),
                entity.getBundleId(),
                entity.getFirebaseAppId(),
                entity.getDistributionChannel(),
                entity.getDistributionGroup(),
                entity.getStatus().name(),
                entity.getUpdatedAt()
        );
    }

    private TenantApplicationStatus parseApplicationStatus(String value) {
        try {
            return TenantApplicationStatus.valueOf(value.trim().toUpperCase(Locale.ROOT));
        } catch (Exception ex) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "APPLICATION_STATUS_INVALID",
                    "Status de aplicativo invalido",
                    ErrorSeverity.ERROR,
                    "Use DRAFT, READY ou ACTIVE.",
                    "value=" + value
            );
        }
    }

    private LicenseModel parseLicenseModel(String value) {
        try {
            return LicenseModel.valueOf(value.trim().toUpperCase(Locale.ROOT));
        } catch (Exception ex) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "LICENSE_MODEL_INVALID",
                    "Modelo de licenca invalido",
                    ErrorSeverity.ERROR,
                    "Use PER_USER.",
                    "value=" + value
            );
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }

    private String trimToNull(String value) {
        String trimmed = trim(value);
        return StringUtils.hasText(trimmed) ? trimmed : null;
    }

    private User ensureAdminUser(String tenantId, User existing, UpsertTenantAdminHandoffRequest request) {
        Membership membership = membershipRepository
                .findByTenant_IdAndRoleAndStatus(tenantId, MembershipRole.TENANT_ADMIN, MembershipStatus.ACTIVE)
                .orElse(null);
        if (membership != null && !membership.getUser().getId().equals(existing.getId())) {
            throw new ApiContractException(
                    HttpStatus.CONFLICT,
                    "TENANT_ADMIN_ALREADY_PROVISIONED",
                    "Tenant ja possui admin inicial provisionado com outro email",
                    ErrorSeverity.ERROR,
                    "Use o email do admin atual ou alinhe a troca de handoff antes de continuar.",
                    "tenantId=" + tenantId
            );
        }

        User hydrated = userRepository.findByTenantIdAndId(tenantId, existing.getId())
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "USER_NOT_FOUND",
                        "Usuario nao encontrado para handoff",
                        ErrorSeverity.ERROR,
                        "Revise o cadastro do admin inicial e tente novamente.",
                        "tenantId=" + tenantId + ", email=" + request.email()
                ));

        Membership userMembership = membershipRepository.findByUser_IdAndTenant_Id(hydrated.getId(), tenantId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.CONFLICT,
                        "TENANT_ADMIN_MEMBERSHIP_REQUIRED",
                        "Usuario existente nao possui membership no tenant",
                        ErrorSeverity.ERROR,
                        "Promova o usuario a admin do tenant antes de reutilizar o handoff.",
                        "tenantId=" + tenantId + ", email=" + request.email()
                ));

        if (userMembership.getRole() != MembershipRole.TENANT_ADMIN) {
            throw new ApiContractException(
                    HttpStatus.CONFLICT,
                    "TENANT_ADMIN_ROLE_REQUIRED",
                    "Usuario existente nao e admin do tenant",
                    ErrorSeverity.ERROR,
                    "Use um usuario admin existente ou crie um admin inicial dedicado.",
                    "tenantId=" + tenantId + ", email=" + request.email()
            );
        }

        hydrated.setNome(trim(request.nome()));
        hydrated.setTipo(trim(request.tipo()));
        hydrated.setCpf(trimToNull(request.cpf()));
        hydrated.setCnpj(trimToNull(request.cnpj()));
        hydrated.setExternalId(trimToNull(request.externalId()));
        return userRepository.save(hydrated);
    }

    private TenantAdminHandoffResponse toAdminHandoffResponse(String tenantId, String temporaryPassword) {
        Membership membership = membershipRepository
                .findByTenant_IdAndRoleAndStatus(tenantId, MembershipRole.TENANT_ADMIN, MembershipStatus.ACTIVE)
                .orElse(null);
        if (membership == null) {
            return new TenantAdminHandoffResponse(tenantId, null, false, null, temporaryPassword);
        }

        User adminUser = userRepository.findByTenantIdAndId(tenantId, membership.getUser().getId())
                .orElse(membership.getUser());
        UserCredentialEntity credential = userCredentialRepository.findByTenantIdAndUserId(tenantId, adminUser.getId())
                .orElse(null);
        adminUser.setRole(UserRole.ADMIN);

        return new TenantAdminHandoffResponse(
                tenantId,
                UserResponse.from(adminUser),
                credential != null,
                credential != null ? credential.getUpdatedAt() : null,
                temporaryPassword
        );
    }
}
