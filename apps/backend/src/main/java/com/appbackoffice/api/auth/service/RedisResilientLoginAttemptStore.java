package com.appbackoffice.api.auth.service;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RedisResilientLoginAttemptStore implements LoginAttemptStore {

    private final StringRedisTemplate redisTemplate;
    private final ConcurrentHashMap<String, InMemoryAttempt> fallback = new ConcurrentHashMap<>();

    public RedisResilientLoginAttemptStore(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Override
    public LoginAttemptStatus increment(String key, Duration window) {
        String redisKey = "auth:attempt:" + key;
        try {
            Long count = redisTemplate.opsForValue().increment(redisKey);
            if (count != null && count == 1L) {
                redisTemplate.expire(redisKey, window);
            }
            Long ttl = redisTemplate.getExpire(redisKey);
            long retryAfter = ttl != null && ttl > 0 ? ttl : window.getSeconds();
            return new LoginAttemptStatus(count == null ? 1 : count.intValue(), retryAfter);
        } catch (Exception ignored) {
            InMemoryAttempt state = fallback.compute(redisKey, (k, current) -> {
                Instant now = Instant.now();
                if (current == null || current.expiresAt().isBefore(now)) {
                    return new InMemoryAttempt(1, now.plus(window));
                }
                return new InMemoryAttempt(current.count() + 1, current.expiresAt());
            });
            long retryAfter = Duration.between(Instant.now(), state.expiresAt()).toSeconds();
            return new LoginAttemptStatus(state.count(), Math.max(1, retryAfter));
        }
    }

    @Override
    public void reset(String key) {
        String redisKey = "auth:attempt:" + key;
        try {
            redisTemplate.delete(redisKey);
        } catch (Exception ignored) {
            // no-op
        }
        fallback.remove(redisKey);
    }

    private record InMemoryAttempt(int count, Instant expiresAt) {
    }
}
