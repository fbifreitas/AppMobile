package com.appbackoffice.api.integration;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.servlet.HandlerExceptionResolver;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class MobileGatewayPolicyFilter extends OncePerRequestFilter {

    private static final String API_VERSION = "v1";
    private static final int RATE_LIMIT_PER_MINUTE = 120;
    private static final long WINDOW_SECONDS = 60;
    private static final long REPLAY_WINDOW_SECONDS = 300;
    private static final String REQUEST_TIMESTAMP_HEADER = "X-Request-Timestamp";
    private static final String REQUEST_NONCE_HEADER = "X-Request-Nonce";
    private final Map<String, Deque<Long>> requestsByKey = new ConcurrentHashMap<>();
    private final Map<String, Long> seenNonces = new ConcurrentHashMap<>();
    private final HandlerExceptionResolver handlerExceptionResolver;

    public MobileGatewayPolicyFilter(HandlerExceptionResolver handlerExceptionResolver) {
        this.handlerExceptionResolver = handlerExceptionResolver;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String uri = request.getRequestURI();
        return uri == null || !uri.startsWith("/api/mobile/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        try {
            enforceRateLimit(request);
            enforceReplayProtection(request);
            response.setHeader("X-Api-Version", API_VERSION);
            filterChain.doFilter(request, response);
        } catch (ApiContractException exception) {
            handlerExceptionResolver.resolveException(request, response, null, exception);
        }
    }

    private void enforceRateLimit(HttpServletRequest request) {
        String tenantId = normalize(request.getHeader("X-Tenant-Id"), "unknown-tenant");
        String actorId = normalize(request.getHeader("X-Actor-Id"), "unknown-actor");
        String key = tenantId + "::" + actorId;

        long now = Instant.now().getEpochSecond();
        Deque<Long> deque = requestsByKey.computeIfAbsent(key, ignored -> new ArrayDeque<>());
        synchronized (deque) {
            while (!deque.isEmpty() && (now - deque.peekFirst()) >= WINDOW_SECONDS) {
                deque.removeFirst();
            }

            if (deque.size() >= RATE_LIMIT_PER_MINUTE) {
                throw new ApiContractException(
                        HttpStatus.TOO_MANY_REQUESTS,
                        "REQ_RATE_LIMITED",
                        "Limite de requisicoes mobile excedido",
                        ErrorSeverity.ERROR,
                        "Aguarde alguns segundos antes de tentar novamente.",
                        "limitPerMinute=" + RATE_LIMIT_PER_MINUTE
                );
            }

            deque.addLast(now);
        }
    }

    private void enforceReplayProtection(HttpServletRequest request) {
        if (!requiresReplayProtection(request)) {
            return;
        }

        String timestampHeader = request.getHeader(REQUEST_TIMESTAMP_HEADER);
        if (!StringUtils.hasText(timestampHeader)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "REQUEST_TIMESTAMP_REQUIRED",
                    "X-Request-Timestamp is required",
                    ErrorSeverity.ERROR,
                    "Send X-Request-Timestamp in UTC ISO-8601 format for protected mobile write operations.",
                    "header: " + REQUEST_TIMESTAMP_HEADER
            );
        }

        String nonceHeader = request.getHeader(REQUEST_NONCE_HEADER);
        if (!StringUtils.hasText(nonceHeader)) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "REQUEST_NONCE_REQUIRED",
                    "X-Request-Nonce is required",
                    ErrorSeverity.ERROR,
                    "Send a unique X-Request-Nonce for each protected mobile write operation.",
                    "header: " + REQUEST_NONCE_HEADER
            );
        }

        Instant requestInstant = parseRequestInstant(timestampHeader.trim());
        long now = Instant.now().getEpochSecond();
        long requestEpoch = requestInstant.getEpochSecond();
        if (Math.abs(now - requestEpoch) > REPLAY_WINDOW_SECONDS) {
            throw new ApiContractException(
                    HttpStatus.PRECONDITION_FAILED,
                    "REQUEST_TIMESTAMP_EXPIRED",
                    "Request timestamp is outside the accepted replay window",
                    ErrorSeverity.ERROR,
                    "Retry the operation with a fresh X-Request-Timestamp and X-Request-Nonce.",
                    "acceptedWindowSeconds=" + REPLAY_WINDOW_SECONDS
            );
        }

        cleanupExpiredNonces(now);

        String tenantId = normalize(request.getHeader("X-Tenant-Id"), "unknown-tenant");
        String actorId = normalize(request.getHeader("X-Actor-Id"), "unknown-actor");
        String nonceKey = tenantId + "::" + actorId + "::" + nonceHeader.trim();
        Long previousSeenAt = seenNonces.putIfAbsent(nonceKey, now);
        if (previousSeenAt != null && (now - previousSeenAt) <= REPLAY_WINDOW_SECONDS) {
            throw new ApiContractException(
                    HttpStatus.CONFLICT,
                    "REQUEST_REPLAY_DETECTED",
                    "Replay detected for protected mobile write operation",
                    ErrorSeverity.ERROR,
                    "Generate a fresh X-Request-Nonce before retrying the protected write.",
                    "header: " + REQUEST_NONCE_HEADER
            );
        }
    }

    private boolean requiresReplayProtection(HttpServletRequest request) {
        return "POST".equalsIgnoreCase(request.getMethod())
                && "/api/mobile/inspections/finalized".equals(request.getRequestURI());
    }

    private Instant parseRequestInstant(String rawTimestamp) {
        try {
            return Instant.parse(rawTimestamp);
        } catch (DateTimeParseException exception) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "REQUEST_TIMESTAMP_INVALID",
                    "X-Request-Timestamp must be a valid UTC ISO-8601 instant",
                    ErrorSeverity.ERROR,
                    "Send X-Request-Timestamp using a value such as 2026-04-08T17:45:30Z.",
                    "header: " + REQUEST_TIMESTAMP_HEADER
            );
        }
    }

    private void cleanupExpiredNonces(long nowEpochSecond) {
        seenNonces.entrySet().removeIf(entry -> (nowEpochSecond - entry.getValue()) > REPLAY_WINDOW_SECONDS);
    }

    private String normalize(String value, String fallback) {
        if (!StringUtils.hasText(value)) {
            return fallback;
        }
        return value.trim();
    }
}
