package com.appbackoffice.api.auth;

import com.appbackoffice.api.auth.dto.AuthMeResponse;
import com.appbackoffice.api.auth.dto.AuthTokenResponse;
import com.appbackoffice.api.auth.dto.FirstAccessCompleteRequest;
import com.appbackoffice.api.auth.dto.FirstAccessStartRequest;
import com.appbackoffice.api.auth.dto.FirstAccessStartResponse;
import com.appbackoffice.api.auth.dto.LoginRequest;
import com.appbackoffice.api.auth.dto.LogoutRequest;
import com.appbackoffice.api.auth.dto.RefreshTokenRequest;
import com.appbackoffice.api.auth.service.AuthService;
import com.appbackoffice.api.auth.service.FirstAccessService;
import com.appbackoffice.api.user.dto.OnboardingPendingResponse;
import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.contract.RequestContextValidator;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;
    private final FirstAccessService firstAccessService;

    public AuthController(AuthService authService, FirstAccessService firstAccessService) {
        this.authService = authService;
        this.firstAccessService = firstAccessService;
    }

    @PostMapping("/login")
    public AuthTokenResponse login(@RequestHeader("X-Correlation-Id") String correlationId,
                                   @Valid @RequestBody LoginRequest request,
                                   HttpServletRequest httpRequest) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return authService.login(request, httpRequest.getRemoteAddr());
    }

    @PostMapping("/first-access/start")
    public FirstAccessStartResponse startFirstAccess(@RequestHeader("X-Correlation-Id") String correlationId,
                                                     @Valid @RequestBody FirstAccessStartRequest request) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return firstAccessService.start(request);
    }

    @PostMapping("/first-access/complete")
    public AuthTokenResponse completeFirstAccess(@RequestHeader("X-Correlation-Id") String correlationId,
                                                @Valid @RequestBody FirstAccessCompleteRequest request,
                                                HttpServletRequest httpRequest) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return firstAccessService.complete(request, httpRequest.getRemoteAddr());
    }

    @PostMapping("/refresh")
    public AuthTokenResponse refresh(@RequestHeader("X-Correlation-Id") String correlationId,
                                     @Valid @RequestBody RefreshTokenRequest request) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return authService.refresh(request.refreshToken());
    }

    @PostMapping("/logout")
    public void logout(@RequestHeader("X-Correlation-Id") String correlationId,
                       @Valid @RequestBody LogoutRequest request) {
        RequestContextValidator.requireCorrelationId(correlationId);
        authService.logout(request.refreshToken());
    }

    @GetMapping("/me")
    public AuthMeResponse me(@RequestHeader("X-Correlation-Id") String correlationId,
                             @RequestHeader("Authorization") String authorizationHeader) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return authService.me(extractBearer(authorizationHeader));
    }

    @GetMapping("/onboarding-pending")
    public OnboardingPendingResponse onboardingPending(@RequestHeader("X-Correlation-Id") String correlationId,
                                                       @RequestHeader("Authorization") String authorizationHeader) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return authService.onboardingPending(extractBearer(authorizationHeader));
    }

    private String extractBearer(String authorizationHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            throw new ApiContractException(
                    HttpStatus.UNAUTHORIZED,
                    "AUTH_INVALID_TOKEN",
                    "Token inválido ou expirado",
                    ErrorSeverity.ERROR,
                    "Envie Authorization: Bearer <token>.",
                    null
            );
        }
        return authorizationHeader.substring("Bearer ".length());
    }
}
