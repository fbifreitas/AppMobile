package com.appbackoffice.api.user.audit;

import com.appbackoffice.api.user.dto.UserAuditEntryResponse;
import com.appbackoffice.api.user.dto.UserAuditResponse;
import com.appbackoffice.api.user.entity.User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class UserAuditService {

    private final UserAuditEntryRepository userAuditEntryRepository;

    public UserAuditService(UserAuditEntryRepository userAuditEntryRepository) {
        this.userAuditEntryRepository = userAuditEntryRepository;
    }

    public void record(User user, String actorId, String correlationId, UserAuditAction action, String details) {
        UserAuditEntryEntity entry = new UserAuditEntryEntity();
        entry.setId("user-audit-" + UUID.randomUUID());
        entry.setTenantId(user.getTenantId());
        entry.setUserId(user.getId());
        entry.setUserEmail(user.getEmail());
        entry.setActorId(actorId);
        entry.setAction(action);
        entry.setCorrelationId(correlationId);
        entry.setDetails(details);
        entry.setCreatedAt(Instant.now());
        userAuditEntryRepository.save(entry);
    }

    @Transactional(readOnly = true)
    public UserAuditResponse listAudit(String tenantId, Long userId) {
        List<UserAuditEntryEntity> items = userId == null
                ? userAuditEntryRepository.findTop50ByTenantIdOrderByCreatedAtDesc(tenantId)
                : userAuditEntryRepository.findTop50ByTenantIdAndUserIdOrderByCreatedAtDesc(tenantId, userId);

        List<UserAuditEntryResponse> responses = items.stream()
                .map(entry -> new UserAuditEntryResponse(
                        entry.getId(),
                        entry.getUserId(),
                        entry.getUserEmail(),
                        entry.getActorId(),
                        entry.getAction().name(),
                        entry.getCorrelationId(),
                        entry.getDetails(),
                        entry.getCreatedAt()
                ))
                .toList();

        return new UserAuditResponse(responses, responses.size(), Instant.now());
    }
}