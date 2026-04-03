package com.appbackoffice.api.user.service;

import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserLifecycle;
import com.appbackoffice.api.user.entity.UserLifecycleStatus;
import com.appbackoffice.api.user.repository.UserLifecycleRepository;
import org.springframework.stereotype.Service;

@Service
public class UserLifecycleService {

    private final UserLifecycleRepository userLifecycleRepository;

    public UserLifecycleService(UserLifecycleRepository userLifecycleRepository) {
        this.userLifecycleRepository = userLifecycleRepository;
    }

    public void initializePending(User user) {
        upsert(user, UserLifecycleStatus.PENDING_APPROVAL, null);
    }

    public void initializeApproved(User user) {
        upsert(user, UserLifecycleStatus.APPROVED, null);
    }

    public void markApproved(User user) {
        upsert(user, UserLifecycleStatus.APPROVED, null);
    }

    public void markRejected(User user, String reason) {
        upsert(user, UserLifecycleStatus.REJECTED, reason);
    }

    private void upsert(User user, UserLifecycleStatus status, String reason) {
        UserLifecycle lifecycle = userLifecycleRepository
                .findByUserIdAndTenantId(user.getId(), user.getTenantId())
                .orElseGet(() -> new UserLifecycle(user, user.getTenantId(), status, reason));

        lifecycle.setStatus(status);
        lifecycle.setReason(reason);
        lifecycle.setTenantId(user.getTenantId());

        user.setLifecycle(lifecycle);
        userLifecycleRepository.save(lifecycle);
    }
}
