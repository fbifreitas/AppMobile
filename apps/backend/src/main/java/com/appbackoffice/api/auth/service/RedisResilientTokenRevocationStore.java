package com.appbackoffice.api.auth.service;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RedisResilientTokenRevocationStore implements TokenRevocationStore {

    private final StringRedisTemplate redisTemplate;
    private final ConcurrentHashMap<String, Instant> fallback = new ConcurrentHashMap<>();

    public RedisResilientTokenRevocationStore(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Override
    public void revoke(String tokenKey, Duration ttl) {
        String redisKey = "auth:revoked:" + tokenKey;
        Duration safeTtl = ttl.isNegative() || ttl.isZero() ? Duration.ofSeconds(1) : ttl;
        try {
            redisTemplate.opsForValue().set(redisKey, "1", safeTtl);
            return;
        } catch (Exception ignored) {
            // fallback in-memory
        }
        fallback.put(redisKey, Instant.now().plus(safeTtl));
    }

    @Override
    public boolean isRevoked(String tokenKey) {
        String redisKey = "auth:revoked:" + tokenKey;
        try {
            Boolean exists = redisTemplate.hasKey(redisKey);
            if (exists != null) {
                return exists;
            }
        } catch (Exception ignored) {
            // fallback in-memory
        }
        Instant expiresAt = fallback.get(redisKey);
        if (expiresAt == null) {
            return false;
        }
        if (expiresAt.isBefore(Instant.now())) {
            fallback.remove(redisKey);
            return false;
        }
        return true;
    }
}
