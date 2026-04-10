package com.appbackoffice.api.auth.service;

import com.appbackoffice.api.auth.dto.AuthTokenResponse;
import com.appbackoffice.api.auth.dto.FirstAccessCompleteRequest;
import com.appbackoffice.api.auth.dto.FirstAccessStartRequest;
import com.appbackoffice.api.auth.dto.FirstAccessStartResponse;
import com.appbackoffice.api.auth.dto.LoginRequest;
import com.appbackoffice.api.auth.entity.FirstAccessOtpEntity;
import com.appbackoffice.api.auth.entity.UserCredentialEntity;
import com.appbackoffice.api.auth.repository.FirstAccessOtpRepository;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Service
public class FirstAccessService {

    private static final int MAX_ATTEMPTS = 5;

    private final UserRepository userRepository;
    private final UserCredentialRepository userCredentialRepository;
    private final FirstAccessOtpRepository firstAccessOtpRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthService authService;
    private final SecureRandom secureRandom = new SecureRandom();
    private final Duration otpTtl;
    private final boolean exposeDebugOtp;

    public FirstAccessService(UserRepository userRepository,
                              UserCredentialRepository userCredentialRepository,
                              FirstAccessOtpRepository firstAccessOtpRepository,
                              PasswordEncoder passwordEncoder,
                              AuthService authService,
                              @Value("${auth.first-access.otp-ttl-minutes:10}") long otpTtlMinutes,
                              @Value("${auth.first-access.expose-debug-otp:false}") boolean exposeDebugOtp) {
        this.userRepository = userRepository;
        this.userCredentialRepository = userCredentialRepository;
        this.firstAccessOtpRepository = firstAccessOtpRepository;
        this.passwordEncoder = passwordEncoder;
        this.authService = authService;
        this.otpTtl = Duration.ofMinutes(otpTtlMinutes);
        this.exposeDebugOtp = exposeDebugOtp;
    }

    @Transactional
    public FirstAccessStartResponse start(FirstAccessStartRequest request) {
        Optional<User> user = userRepository.findByTenantIdAndCpfAndBirthDateAndExternalId(
                normalize(request.tenantId()),
                onlyDigits(request.cpf()),
                request.birthDate(),
                normalize(request.identifier())
        );

        if (user.isEmpty()) {
            // Neutral response: CPF/data/identificador localizam cadastro, mas nao enumeram usuarios.
            return new FirstAccessStartResponse(
                    UUID.randomUUID().toString(),
                    "Se os dados estiverem corretos, enviaremos um codigo ao contato cadastrado.",
                    otpTtl.toSeconds(),
                    null
            );
        }

        String otp = generateOtp();
        FirstAccessOtpEntity challenge = new FirstAccessOtpEntity();
        challenge.setId(UUID.randomUUID().toString());
        challenge.setTenantId(user.get().getTenantId());
        challenge.setUserId(user.get().getId());
        challenge.setOtpHash(passwordEncoder.encode(otp));
        challenge.setExpiresAt(Instant.now().plus(otpTtl));
        challenge.setAttempts(0);
        firstAccessOtpRepository.save(challenge);

        return new FirstAccessStartResponse(
                challenge.getId(),
                deliveryHint(user.get()),
                otpTtl.toSeconds(),
                exposeDebugOtp ? otp : null
        );
    }

    @Transactional
    public AuthTokenResponse complete(FirstAccessCompleteRequest request, String clientIp) {
        FirstAccessOtpEntity challenge = firstAccessOtpRepository
                .findByIdAndTenantId(request.challengeId(), normalize(request.tenantId()))
                .orElseThrow(this::invalidChallenge);

        if (challenge.getConsumedAt() != null || challenge.getExpiresAt().isBefore(Instant.now())) {
            throw invalidChallenge();
        }
        if (challenge.getAttempts() >= MAX_ATTEMPTS) {
            throw new ApiContractException(
                    HttpStatus.LOCKED,
                    "FIRST_ACCESS_OTP_LOCKED",
                    "Codigo bloqueado por excesso de tentativas",
                    ErrorSeverity.ERROR,
                    "Solicite um novo codigo de primeiro acesso.",
                    "challengeId=" + challenge.getId()
            );
        }

        challenge.setAttempts(challenge.getAttempts() + 1);
        if (!passwordEncoder.matches(request.otp().trim(), challenge.getOtpHash())) {
            firstAccessOtpRepository.save(challenge);
            throw invalidChallenge();
        }

        User user = userRepository.findByTenantIdAndId(challenge.getTenantId(), challenge.getUserId())
                .orElseThrow(this::invalidChallenge);

        UserCredentialEntity credential = userCredentialRepository
                .findByTenantIdAndUserId(user.getTenantId(), user.getId())
                .orElseGet(UserCredentialEntity::new);
        credential.setTenantId(user.getTenantId());
        credential.setUserId(user.getId());
        credential.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userCredentialRepository.save(credential);

        challenge.setConsumedAt(Instant.now());
        firstAccessOtpRepository.save(challenge);

        return authService.login(
                new LoginRequest(user.getTenantId(), user.getEmail(), request.newPassword(), request.deviceInfo()),
                clientIp
        );
    }

    private ApiContractException invalidChallenge() {
        return new ApiContractException(
                HttpStatus.UNAUTHORIZED,
                "FIRST_ACCESS_INVALID_OR_EXPIRED",
                "Codigo invalido ou expirado",
                ErrorSeverity.ERROR,
                "Solicite um novo codigo e tente novamente.",
                null
        );
    }

    private String deliveryHint(User user) {
        String phone = user.getPhone();
        if (phone != null && !phone.isBlank()) {
            return "Codigo enviado ao telefone cadastrado final " + last(phone, 4) + ".";
        }
        return "Codigo enviado ao e-mail cadastrado " + maskEmail(user.getEmail()) + ".";
    }

    private String generateOtp() {
        return String.format("%06d", secureRandom.nextInt(1_000_000));
    }

    private String maskEmail(String email) {
        int at = email.indexOf('@');
        if (at <= 1) {
            return "***";
        }
        return email.charAt(0) + "***" + email.substring(at);
    }

    private String onlyDigits(String value) {
        return value == null ? "" : value.replaceAll("\\D+", "");
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim();
    }

    private String last(String value, int size) {
        String digits = onlyDigits(value);
        return digits.length() <= size ? digits : digits.substring(digits.length() - size);
    }
}
