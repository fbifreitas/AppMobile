package com.appbackoffice.api.policy;

public interface DomainPolicy<T> {
    boolean isAllowed(String actorId, String tenantId, String action, T resource);
}
