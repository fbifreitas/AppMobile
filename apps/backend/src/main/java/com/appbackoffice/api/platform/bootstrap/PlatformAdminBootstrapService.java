package com.appbackoffice.api.platform.bootstrap;

import com.appbackoffice.api.auth.entity.UserCredentialEntity;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.identity.entity.Membership;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.identity.entity.MembershipStatus;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.entity.UserRole;
import com.appbackoffice.api.user.entity.UserSource;
import com.appbackoffice.api.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class PlatformAdminBootstrapService {

    private static final Logger log = LoggerFactory.getLogger(PlatformAdminBootstrapService.class);

    private final TenantRepository tenantRepository;
    private final UserRepository userRepository;
    private final MembershipRepository membershipRepository;
    private final UserCredentialRepository userCredentialRepository;
    private final PasswordEncoder passwordEncoder;
    private final boolean enabled;
    private final String tenantId;
    private final String tenantSlug;
    private final String tenantName;
    private final String adminEmail;
    private final String adminName;
    private final String adminPassword;

    public PlatformAdminBootstrapService(TenantRepository tenantRepository,
                                         UserRepository userRepository,
                                         MembershipRepository membershipRepository,
                                         UserCredentialRepository userCredentialRepository,
                                         PasswordEncoder passwordEncoder,
                                         @Value("${platform.bootstrap.enabled:false}") boolean enabled,
                                         @Value("${platform.bootstrap.tenant-id:tenant-platform}") String tenantId,
                                         @Value("${platform.bootstrap.tenant-slug:platform}") String tenantSlug,
                                         @Value("${platform.bootstrap.tenant-name:Platform}") String tenantName,
                                         @Value("${platform.bootstrap.admin-email:}") String adminEmail,
                                         @Value("${platform.bootstrap.admin-name:Platform Admin}") String adminName,
                                         @Value("${platform.bootstrap.admin-password:}") String adminPassword) {
        this.tenantRepository = tenantRepository;
        this.userRepository = userRepository;
        this.membershipRepository = membershipRepository;
        this.userCredentialRepository = userCredentialRepository;
        this.passwordEncoder = passwordEncoder;
        this.enabled = enabled;
        this.tenantId = tenantId;
        this.tenantSlug = tenantSlug;
        this.tenantName = tenantName;
        this.adminEmail = adminEmail;
        this.adminName = adminName;
        this.adminPassword = adminPassword;
    }

    @Transactional
    public void bootstrap() {
        if (!enabled) {
            return;
        }

        if (!StringUtils.hasText(adminEmail) || !StringUtils.hasText(adminPassword)) {
            throw new IllegalStateException("platform bootstrap enabled but admin email/password are not configured");
        }

        Tenant tenant = tenantRepository.findById(tenantId)
                .map(existing -> {
                    existing.setSlug(tenantSlug.trim());
                    existing.setDisplayName(tenantName.trim());
                    existing.setStatus(TenantStatus.ACTIVE);
                    return tenantRepository.save(existing);
                })
                .orElseGet(() -> tenantRepository.save(new Tenant(
                        tenantId.trim(),
                        tenantSlug.trim(),
                        tenantName.trim(),
                        TenantStatus.ACTIVE
                )));

        User adminUser = userRepository.findByTenantIdAndEmail(tenant.getId(), adminEmail.trim())
                .map(existing -> {
                    existing.setNome(adminName.trim());
                    existing.setTipo("PJ");
                    existing.setStatus(com.appbackoffice.api.user.entity.UserStatus.APPROVED);
                    existing.setRole(UserRole.ADMIN);
                    existing.setSource(UserSource.WEB_CREATED);
                    return userRepository.save(existing);
                })
                .orElseGet(() -> userRepository.save(new User(
                        tenant.getId(),
                        adminEmail.trim(),
                        adminName.trim(),
                        "PJ",
                        UserRole.ADMIN,
                        UserSource.WEB_CREATED
                )));

        Membership membership = membershipRepository.findByUser_IdAndTenant_Id(adminUser.getId(), tenant.getId())
                .orElseGet(Membership::new);
        membership.setUser(adminUser);
        membership.setTenant(tenant);
        membership.setRole(MembershipRole.PLATFORM_ADMIN);
        membership.setStatus(MembershipStatus.ACTIVE);
        membershipRepository.save(membership);

        UserCredentialEntity credential = userCredentialRepository.findByTenantIdAndUserId(tenant.getId(), adminUser.getId())
                .orElseGet(UserCredentialEntity::new);
        credential.setTenantId(tenant.getId());
        credential.setUserId(adminUser.getId());
        credential.setPasswordHash(passwordEncoder.encode(adminPassword));
        userCredentialRepository.save(credential);

        log.info("Platform bootstrap ensured tenant={} email={}", tenant.getId(), adminUser.getEmail());
    }
}
