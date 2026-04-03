package com.appbackoffice.api.auth;

import com.appbackoffice.api.auth.dto.AuthMeResponse;
import com.appbackoffice.api.auth.dto.AuthTokenResponse;
import com.appbackoffice.api.auth.dto.LoginRequest;
import com.appbackoffice.api.auth.dto.LogoutRequest;
import com.appbackoffice.api.auth.dto.RefreshTokenRequest;
import com.appbackoffice.api.auth.service.AuthService;
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

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public AuthTokenResponse login(@RequestHeader("X-Correlation-Id") String correlationId,
                                   @Valid @RequestBody LoginRequest request,
                                   HttpServletRequest httpRequest) {
        RequestContextValidator.requireCorrelationId(correlationId);
        return authService.login(request, httpRequest.getRemoteAddr());
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
