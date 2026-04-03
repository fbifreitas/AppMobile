package com.appbackoffice.api.auth.provider;

import com.appbackoffice.api.auth.entity.UserCredentialEntity;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserStatus;
import com.appbackoffice.api.user.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class InternalIdentityProvider implements IdentityProvider {

    private final UserRepository userRepository;
    private final UserCredentialRepository userCredentialRepository;
    private final PasswordEncoder passwordEncoder;

    public InternalIdentityProvider(UserRepository userRepository,
                                    UserCredentialRepository userCredentialRepository,
                                    PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.userCredentialRepository = userCredentialRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public AuthenticatedIdentity authenticate(AuthenticationRequest request) {
        User user = userRepository.findByTenantIdAndEmail(request.tenantId(), request.email())
                .orElseThrow(this::invalidCredentials);

        if (user.getStatus() != UserStatus.APPROVED) {
            throw invalidCredentials();
        }

        UserCredentialEntity credential = userCredentialRepository
                .findByTenantIdAndUserId(request.tenantId(), user.getId())
                .orElseThrow(this::invalidCredentials);

        if (!passwordEncoder.matches(request.password(), credential.getPasswordHash())) {
            throw invalidCredentials();
        }

        return new AuthenticatedIdentity(user.getId(), request.tenantId(), user.getEmail());
    }

    @Override
    public AuthenticatedIdentity resolveIdentity(String providerToken, String tenantId) {
        throw new UnsupportedOperationException("Internal provider does not resolve external provider token");
    }

    @Override
    public void revokeSession(String sessionId) {
        // Revogacao efetiva acontece via SessionRepository + TokenRevocationStore
    }

    private ApiContractException invalidCredentials() {
        return new ApiContractException(
                HttpStatus.UNAUTHORIZED,
                "AUTH_INVALID_CREDENTIALS",
                "Credenciais inválidas",
                ErrorSeverity.ERROR,
                "Verifique email e senha e tente novamente.",
                null
        );
    }
}
