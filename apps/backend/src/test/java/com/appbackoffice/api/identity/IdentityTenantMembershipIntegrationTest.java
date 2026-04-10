package com.appbackoffice.api.identity;

import com.appbackoffice.api.identity.entity.Membership;
import com.appbackoffice.api.identity.entity.MembershipRole;
import com.appbackoffice.api.identity.entity.MembershipStatus;
import com.appbackoffice.api.identity.entity.OrganizationUnit;
import com.appbackoffice.api.identity.entity.OrganizationUnitType;
import com.appbackoffice.api.identity.entity.Tenant;
import com.appbackoffice.api.identity.entity.TenantStatus;
import com.appbackoffice.api.auth.repository.IdentityBindingRepository;
import com.appbackoffice.api.auth.repository.SessionRepository;
import com.appbackoffice.api.auth.repository.UserCredentialRepository;
import com.appbackoffice.api.identity.repository.MembershipRepository;
import com.appbackoffice.api.identity.repository.OrganizationUnitRepository;
import com.appbackoffice.api.identity.repository.TenantRepository;
import com.appbackoffice.api.platform.repository.TenantApplicationRepository;
import com.appbackoffice.api.platform.repository.TenantLicenseRepository;
import com.appbackoffice.api.user.entity.User;
import com.appbackoffice.api.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
class IdentityTenantMembershipIntegrationTest {

    @Autowired
    private TenantRepository tenantRepository;

    @Autowired
    private OrganizationUnitRepository organizationUnitRepository;

    @Autowired
    private MembershipRepository membershipRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SessionRepository sessionRepository;

    @Autowired
    private UserCredentialRepository userCredentialRepository;

    @Autowired
    private IdentityBindingRepository identityBindingRepository;

    @Autowired
    private TenantApplicationRepository tenantApplicationRepository;

    @Autowired
    private TenantLicenseRepository tenantLicenseRepository;

    private void cleanAll() {
        sessionRepository.deleteAll();
        identityBindingRepository.deleteAll();
        userCredentialRepository.deleteAll();
        membershipRepository.deleteAll();
        organizationUnitRepository.deleteAll();
        userRepository.deleteAll();
        tenantApplicationRepository.deleteAll();
        tenantLicenseRepository.deleteAll();
        tenantRepository.deleteAll();
    }

    @BeforeEach
    void setUp() {
        cleanAll();
    }

    @AfterEach
    void tearDown() {
        cleanAll();
    }

    @Test
    void shouldPersistTenantsAndIsolateMembershipByTenant() {
        Tenant tenantA = tenantRepository.save(new Tenant("tenant-a", "empresa-ancora", "Empresa Ancora", TenantStatus.ACTIVE));
        Tenant tenantB = tenantRepository.save(new Tenant("tenant-b", "empresa-parceira", "Empresa Parceira", TenantStatus.ACTIVE));

        OrganizationUnit unitA = organizationUnitRepository.save(
                new OrganizationUnit(tenantA, null, "Regional Sul", OrganizationUnitType.REGIONAL)
        );

        User userA = userRepository.save(new User("tenant-a", "operador.a@tenant.com", "Operador A", "PJ"));
        User userB = userRepository.save(new User("tenant-b", "operador.b@tenant.com", "Operador B", "CLT"));

        membershipRepository.save(new Membership(userA, tenantA, unitA, MembershipRole.FIELD_OPERATOR, MembershipStatus.ACTIVE));
        membershipRepository.save(new Membership(userB, tenantB, null, MembershipRole.TENANT_ADMIN, MembershipStatus.ACTIVE));

        assertThat(tenantRepository.findBySlug("empresa-ancora")).isPresent();

        List<Membership> tenantAMemberships = membershipRepository.findByTenant_Id("tenant-a");
        List<Membership> tenantBMemberships = membershipRepository.findByTenant_Id("tenant-b");

        assertThat(tenantAMemberships).hasSize(1);
        assertThat(tenantAMemberships.get(0).getUser().getId()).isEqualTo(userA.getId());

        assertThat(tenantBMemberships).hasSize(1);
        assertThat(tenantBMemberships.get(0).getUser().getId()).isEqualTo(userB.getId());

        assertThat(membershipRepository.findByUser_IdAndTenant_Id(userA.getId(), "tenant-a")).isPresent();
        assertThat(membershipRepository.findByUser_IdAndTenant_Id(userA.getId(), "tenant-b")).isNotPresent();
    }
}
