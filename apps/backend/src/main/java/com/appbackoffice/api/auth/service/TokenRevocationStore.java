package com.appbackoffice.api.auth.service;

import java.time.Duration;

public interface TokenRevocationStore {
    void revoke(String tokenKey, Duration ttl);

    boolean isRevoked(String tokenKey);
}
