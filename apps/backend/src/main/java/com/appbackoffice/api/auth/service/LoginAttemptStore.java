package com.appbackoffice.api.auth.service;

import java.time.Duration;

public interface LoginAttemptStore {
    LoginAttemptStatus increment(String key, Duration window);

    void reset(String key);
}
