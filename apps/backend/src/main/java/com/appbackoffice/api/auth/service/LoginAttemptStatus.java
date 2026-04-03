package com.appbackoffice.api.auth.service;

public record LoginAttemptStatus(int count, long retryAfterSeconds) {
}
