package com.appbackoffice.api.auth.service;

import com.appbackoffice.api.auth.dto.AuthMeResponse;
import com.appbackoffice.api.auth.dto.AuthTokenResponse;
import com.appbackoffice.api.auth.dto.LoginRequest;
import com.appbackoffice.api.auth.entity.IdentityBindingEntity;
import com.appbackoffice.api.auth.entity.IdentityProviderType;
import com.appbackoffice.api.auth.entity.SessionEntity;
import com.appbackoffice.api.auth.provider.AuthenticatedIdentity;
import com.appbackoffice.api.auth.provider.AuthenticationRequest;
import com.appbackoffice.api.auth.provider.IdentityProvider;
import com.appbackoffice.api.auth.repository.IdentityBindingRepository;
import com.appbackoffice.api.auth.repository.SessionRepository;
import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.identity.entity.Membership;
import com.appbackoffice.api.identity.entity.MembershipStatus;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

@Service
public class AuthService {

    private final IdentityProvider identityProvider;
    private final MembershipRepository membershipRepository;
    private final UserRepository userRepository;
    private final SessionRepository sessionRepository;
    private final IdentityBindingRepository identityBindingRepository;
    private final JwtTokenService jwtTokenService;
    private final PermissionCatalog permissionCatalog;
    private final LoginAttemptStore loginAttemptStore;
    private final TokenRevocationStore tokenRevocationStore;
    private final int lockoutMaxAttempts;
    private final Duration lockoutWindow;

    public AuthService(IdentityProvider identityProvider,
                       MembershipRepository membershipRepository,
                       UserRepository userRepository,
                       SessionRepository sessionRepository,
                       IdentityBindingRepository identityBindingRepository,
                       JwtTokenService jwtTokenService,
                       PermissionCatalog permissionCatalog,
                       LoginAttemptStore loginAttemptStore,
                       TokenRevocationStore tokenRevocationStore,
                       @Value("${auth.lockout.max-attempts:5}") int lockoutMaxAttempts,
                       @Value("${auth.lockout.window-minutes:10}") long lockoutWindowMinutes) {
        this.identityProvider = identityProvider;
        this.membershipRepository = membershipRepository;
        this.userRepository = userRepository;
        this.sessionRepository = sessionRepository;
        this.identityBindingRepository = identityBindingRepository;
        this.jwtTokenService = jwtTokenService;
        this.permissionCatalog = permissionCatalog;
        this.loginAttemptStore = loginAttemptStore;
        this.tokenRevocationStore = tokenRevocationStore;
        this.lockoutMaxAttempts = lockoutMaxAttempts;
        this.lockoutWindow = Duration.ofMinutes(lockoutWindowMinutes);
    }

    @Transactional
    public AuthTokenResponse login(LoginRequest request, String clientIp) {
        String attemptKey = attemptKey(request.email(), clientIp);

        try {
            AuthenticatedIdentity identity = identityProvider.authenticate(
                    new AuthenticationRequest(request.tenantId(), request.email(), request.password())
            );

            Membership membership = activeMembership(identity.userId(), identity.tenantId());
            ensureIdentityBinding(identity);
            loginAttemptStore.reset(attemptKey);
            return issueSessionTokens(identity, membership, request.deviceInfo());
        } catch (ApiContractException ex) {
            if (HttpStatus.UNAUTHORIZED.equals(ex.getStatus())) {
                LoginAttemptStatus state = loginAttemptStore.increment(attemptKey, lockoutWindow);
                if (state.count() > lockoutMaxAttempts) {
                    throw new ApiContractException(
                            HttpStatus.LOCKED,
                            "AUTH_ACCOUNT_LOCKED",
                            "Conta temporariamente bloqueada por excesso de tentativas",
                            ErrorSeverity.ERROR,
                            "Aguarde o tempo informado e tente novamente.",
                            "retryAfterSeconds=" + state.retryAfterSeconds()
                    );
                }
            }
            throw ex;
        }
    }

    @Transactional
    public AuthTokenResponse refresh(String refreshToken) {
        String hash = hashToken(refreshToken);

        if (tokenRevocationStore.isRevoked(hash)) {
            throw invalidToken();
        }

        SessionEntity session = sessionRepository.findByRefreshTokenHashAndRevokedAtIsNull(hash)
                .orElseThrow(this::invalidToken);

        if (session.getExpiresAt().isBefore(Instant.now())) {
            throw invalidToken();
        }

        User user = userRepository.findByTenantIdAndId(session.getTenantId(), session.getUserId())
                .orElseThrow(this::invalidToken);
        Membership membership = activeMembership(user.getId(), session.getTenantId());

        String newRefresh = UUID.randomUUID().toString();
        session.setRefreshTokenHash(hashToken(newRefresh));
        session.setExpiresAt(Instant.now().plus(jwtTokenService.refreshTokenTtl()));
        sessionRepository.save(session);

        String access = jwtTokenService.generateAccessToken(
                user.getId(),
                session.getTenantId(),
                membership.getOrganizationUnit() != null ? String.valueOf(membership.getOrganizationUnit().getId()) : null,
                List.of(membership.getRole().name())
        );

        return new AuthTokenResponse(access, newRefresh, "Bearer", jwtTokenService.accessTokenTtl().toSeconds());
    }

    @Transactional
    public void logout(String refreshToken) {
        String hash = hashToken(refreshToken);

        sessionRepository.findByRefreshTokenHashAndRevokedAtIsNull(hash)
                .ifPresent(session -> {
                    session.setRevokedAt(Instant.now());
                    sessionRepository.save(session);
                    tokenRevocationStore.revoke(hash, Duration.between(Instant.now(), session.getExpiresAt()));
                    identityProvider.revokeSession(session.getId());
                });
    }

    @Transactional(readOnly = true)
    public AuthMeResponse me(String accessToken) {
        JwtPrincipal principal = jwtTokenService.parseAndValidate(accessToken);

        if (tokenRevocationStore.isRevoked(principal.tokenId())) {
            throw invalidToken();
        }

        User user = userRepository.findByTenantIdAndId(principal.tenantId(), principal.userId())
                .orElseThrow(this::invalidToken);

        Membership membership = activeMembership(user.getId(), principal.tenantId());

        return new AuthMeResponse(
                user.getId(),
                principal.tenantId(),
                user.getEmail(),
                user.getStatus().name(),
                membership.getRole().name(),
                membership.getStatus().name(),
                permissionCatalog.permissionsFor(membership.getRole())
        );
    }

    private Membership activeMembership(Long userId, String tenantId) {
        Membership membership = membershipRepository.findByUser_IdAndTenant_Id(userId, tenantId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.UNAUTHORIZED,
                        "AUTH_MEMBERSHIP_NOT_FOUND",
                        "Usuário sem membership ativa no tenant",
                        ErrorSeverity.ERROR,
                        "Contate o administrador para revisar permissões.",
                        "tenantId=" + tenantId + ", userId=" + userId
                ));

        if (membership.getStatus() != MembershipStatus.ACTIVE) {
            throw new ApiContractException(
                    HttpStatus.UNAUTHORIZED,
                    "AUTH_MEMBERSHIP_INACTIVE",
                    "Membership inativa para autenticação",
                    ErrorSeverity.ERROR,
                    "Contate o administrador para reativar o acesso.",
                    "tenantId=" + tenantId + ", userId=" + userId
            );
        }
        return membership;
    }

    private void ensureIdentityBinding(AuthenticatedIdentity identity) {
        boolean exists = identityBindingRepository.existsByUserIdAndProviderTypeAndTenantId(
                identity.userId(),
                IdentityProviderType.INTERNAL,
                identity.tenantId()
        );
        if (exists) {
            return;
        }

        IdentityBindingEntity binding = new IdentityBindingEntity();
        binding.setUserId(identity.userId());
        binding.setProviderType(IdentityProviderType.INTERNAL);
        binding.setProviderSub(identity.email());
        binding.setTenantId(identity.tenantId());
        identityBindingRepository.save(binding);
    }

    private AuthTokenResponse issueSessionTokens(AuthenticatedIdentity identity,
                                                 Membership membership,
                                                 String deviceInfo) {
        String refreshToken = UUID.randomUUID().toString();
        String refreshHash = hashToken(refreshToken);

        SessionEntity session = new SessionEntity();
        session.setUserId(identity.userId());
        session.setTenantId(identity.tenantId());
        session.setRefreshTokenHash(refreshHash);
        session.setExpiresAt(Instant.now().plus(jwtTokenService.refreshTokenTtl()));
        session.setDeviceInfo(deviceInfo);
        sessionRepository.save(session);

        String accessToken = jwtTokenService.generateAccessToken(
                identity.userId(),
                identity.tenantId(),
                membership.getOrganizationUnit() != null ? String.valueOf(membership.getOrganizationUnit().getId()) : null,
                List.of(membership.getRole().name())
        );

        return new AuthTokenResponse(accessToken, refreshToken, "Bearer", jwtTokenService.accessTokenTtl().toSeconds());
    }

    private ApiContractException invalidToken() {
        return new ApiContractException(
                HttpStatus.UNAUTHORIZED,
                "AUTH_INVALID_TOKEN",
                "Token inválido ou expirado",
                ErrorSeverity.ERROR,
                "Faça login novamente para obter uma sessão válida.",
                null
        );
    }

    private String attemptKey(String email, String clientIp) {
        return email.toLowerCase() + "|" + (clientIp == null ? "unknown" : clientIp);
    }

    private String hashToken(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(token.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 algorithm unavailable", e);
        }
    }
}
