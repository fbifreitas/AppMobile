package com.appbackoffice.api.config;

import com.appbackoffice.api.config.dto.*;
import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class ConfigPackageService {

    private final ConfigPackageRepository configPackageRepository;
    private final ConfigAuditEntryRepository configAuditEntryRepository;
    private final ConfigPolicyService configPolicyService;

    public ConfigPackageService(
            ConfigPackageRepository configPackageRepository,
            ConfigAuditEntryRepository configAuditEntryRepository,
            ConfigPolicyService configPolicyService
    ) {
        this.configPackageRepository = configPackageRepository;
        this.configAuditEntryRepository = configAuditEntryRepository;
        this.configPolicyService = configPolicyService;
    }

    @Transactional(readOnly = true)
    public ConfigPackagesResponse listPackages(String tenantId, ActorRole actorRole) {
        configPolicyService.assertAllowed(actorRole, ConfigAction.READ);
        List<ConfigPackageResponse> items = configPackageRepository.findByTenantIdOrderByUpdatedAtAsc(tenantId)
                .stream()
                .map(this::toResponse)
                .toList();
        return new ConfigPackagesResponse(items, items.size(), Instant.now().toString());
    }

    public ConfigMutationResponse publish(ConfigPackagePublishRequest request) {
        ActorRole actorRole = parseActorRole(request.actorRole());
        configPolicyService.assertAllowed(actorRole, ConfigAction.PUBLISH);

        ConfigPackageEntity entity = new ConfigPackageEntity();
        entity.setId("cfg-" + request.scope().toLowerCase() + "-" + UUID.randomUUID());
        entity.setScope(parseScope(request.scope()));
        entity.setTenantId(request.tenantId());
        if (request.selector() != null) {
            entity.setUnitId(request.selector().unitId());
            entity.setRoleId(request.selector().roleId());
            entity.setUserId(request.selector().userId());
            entity.setDeviceId(request.selector().deviceId());
        }
        entity.setUpdatedAt(Instant.now());
        entity.setStatus(ConfigPackageStatus.PENDING_APPROVAL);
        entity.setRolloutActivation(parseRolloutActivation(request.rollout()));
        entity.setRolloutStartsAt(parseInstant(request.rollout() != null ? request.rollout().startsAt() : null));
        entity.setRolloutEndsAt(parseInstant(request.rollout() != null ? request.rollout().endsAt() : null));
        entity.setBatchUserIdsCsv(request.rollout() != null && request.rollout().batchUserIds() != null
                ? String.join(",", request.rollout().batchUserIds())
                : null);
        applyRules(entity, request.rules());

        ConfigPackageEntity created = configPackageRepository.save(entity);
        saveAudit(created, request.actorId(), actorRole, ConfigAuditAction.PUBLISH);

        return new ConfigMutationResponse(
                "Pacote publicado com sucesso",
                new ConfigMutationResultResponse(toResponse(created), null)
        );
    }

    public ConfigMutationResponse approve(ConfigPackageActionRequest request) {
        ActorRole actorRole = parseActorRole(request.actorRole());
        configPolicyService.assertAllowed(actorRole, ConfigAction.APPROVE);

        ConfigPackageEntity entity = findPackage(request.packageId(), request.tenantId());
        if (entity.getStatus() == ConfigPackageStatus.ROLLED_BACK) {
            throw notFoundOrInvalid();
        }
        entity.setStatus(ConfigPackageStatus.ACTIVE);
        entity.setUpdatedAt(Instant.now());

        ConfigPackageEntity updated = configPackageRepository.save(entity);
        saveAudit(updated, request.actorId(), actorRole, ConfigAuditAction.APPROVE);
        return new ConfigMutationResponse(
                "Pacote aprovado com sucesso",
                new ConfigMutationResultResponse(null, toResponse(updated))
        );
    }

    public ConfigMutationResponse rollback(ConfigPackageActionRequest request) {
        ActorRole actorRole = parseActorRole(request.actorRole());
        configPolicyService.assertAllowed(actorRole, ConfigAction.ROLLBACK);

        ConfigPackageEntity entity = findPackage(request.packageId(), request.tenantId());
        entity.setStatus(ConfigPackageStatus.ROLLED_BACK);
        entity.setUpdatedAt(Instant.now());

        ConfigPackageEntity updated = configPackageRepository.save(entity);
        saveAudit(updated, request.actorId(), actorRole, ConfigAuditAction.ROLLBACK);
        return new ConfigMutationResponse(
                "Pacote revertido com sucesso",
                new ConfigMutationResultResponse(null, toResponse(updated))
        );
    }

    @Transactional(readOnly = true)
    public ConfigResolveResponse resolve(
            String tenantId,
            String unitId,
            String roleId,
            String userId,
            String deviceId,
            ActorRole actorRole
    ) {
        configPolicyService.assertAllowed(actorRole, ConfigAction.READ);

        List<ConfigPackageEntity> all = configPackageRepository.findByTenantIdOrderByUpdatedAtAsc(tenantId);
        List<ConfigPackageEntity> applied = all.stream()
                .filter(entry -> entry.getStatus() == ConfigPackageStatus.ACTIVE)
                .filter(entry -> selectorMatches(entry, tenantId, unitId, roleId, userId, deviceId))
                .filter(entry -> rolloutMatches(entry, userId))
                .sorted(Comparator.comparingInt(entry -> scopeRank(entry.getScope())))
                .toList();

        List<ConfigPackageEntity> skipped = all.stream()
                .filter(entry -> applied.stream().noneMatch(appliedEntry -> appliedEntry.getId().equals(entry.getId())))
                .toList();

        ConfigRulesDto effective = applied.stream().reduce(
                new ConfigRulesAccumulator(),
                ConfigRulesAccumulator::apply,
                ConfigRulesAccumulator::merge
        ).toDto();

        return new ConfigResolveResponse(
                new ConfigResolveInputResponse(tenantId, unitId, roleId, userId, deviceId),
                new ConfigResolveResultResponse(
                        effective,
                        applied.stream().map(this::toResponse).toList(),
                        skipped.stream().map(this::toResponse).toList()
                )
        );
    }

    @Transactional(readOnly = true)
    public ConfigAuditResponse listAudit(String tenantId, ActorRole actorRole) {
        configPolicyService.assertAllowed(actorRole, ConfigAction.READ);
        List<ConfigAuditEntryResponse> items = configAuditEntryRepository.findTop20ByTenantIdOrderByCreatedAtDesc(tenantId)
                .stream()
                .map(entry -> new ConfigAuditEntryResponse(
                        entry.getId(),
                        entry.getPackageId(),
                        entry.getActorId(),
                        entry.getActorRole().name().toLowerCase(),
                        entry.getAction().name().toLowerCase(),
                        entry.getTenantId(),
                        entry.getScope().name().toLowerCase(),
                        entry.getCreatedAt().toString()
                ))
                .toList();
        return new ConfigAuditResponse(items, items.size(), Instant.now().toString());
    }

    private ConfigPackageEntity findPackage(String packageId, String tenantId) {
        return configPackageRepository.findByIdAndTenantId(packageId, tenantId).orElseThrow(this::notFoundOrInvalid);
    }

    private ApiContractException notFoundOrInvalid() {
        return new ApiContractException(
                HttpStatus.NOT_FOUND,
                "CONFIG_PACKAGE_NOT_FOUND",
                "Pacote nao encontrado ou sem condicao de operacao",
                ErrorSeverity.ERROR,
                "Revise o identificador do pacote e o estado atual antes de tentar novamente.",
                null
        );
    }

    private void saveAudit(ConfigPackageEntity entity, String actorId, ActorRole actorRole, ConfigAuditAction action) {
        ConfigAuditEntryEntity audit = new ConfigAuditEntryEntity();
        audit.setId("audit-" + UUID.randomUUID());
        audit.setPackageId(entity.getId());
        audit.setActorId(actorId);
        audit.setActorRole(actorRole);
        audit.setAction(action);
        audit.setTenantId(entity.getTenantId());
        audit.setScope(entity.getScope());
        audit.setCreatedAt(Instant.now());
        configAuditEntryRepository.save(audit);
    }

    private ConfigPackageResponse toResponse(ConfigPackageEntity entity) {
        return new ConfigPackageResponse(
                entity.getId(),
                entity.getScope().name().toLowerCase(),
                entity.getTenantId(),
                entity.getStatus().name().toLowerCase(),
                entity.getUpdatedAt().toString(),
                new TargetSelectorDto(entity.getUnitId(), entity.getRoleId(), entity.getUserId(), entity.getDeviceId()),
                new RolloutPolicyDto(
                        entity.getRolloutActivation().name().toLowerCase(),
                        entity.getRolloutStartsAt() != null ? entity.getRolloutStartsAt().toString() : null,
                        entity.getRolloutEndsAt() != null ? entity.getRolloutEndsAt().toString() : null,
                        splitCsv(entity.getBatchUserIdsCsv())
                ),
                new ConfigRulesDto(
                        entity.getRequireBiometric(),
                        entity.getCameraMinPhotos(),
                        entity.getCameraMaxPhotos(),
                        entity.getEnableVoiceCommands(),
                        entity.getTheme(),
                        entity.getAppUpdateChannel()
                )
        );
    }

    private void applyRules(ConfigPackageEntity entity, ConfigRulesDto rules) {
        entity.setRequireBiometric(rules.requireBiometric());
        entity.setCameraMinPhotos(rules.cameraMinPhotos());
        entity.setCameraMaxPhotos(rules.cameraMaxPhotos());
        entity.setEnableVoiceCommands(rules.enableVoiceCommands());
        entity.setTheme(rules.theme());
        entity.setAppUpdateChannel(rules.appUpdateChannel());
    }

    private ActorRole parseActorRole(String raw) {
        return ActorRole.valueOf(raw.trim().toUpperCase());
    }

    private ConfigScope parseScope(String raw) {
        return ConfigScope.valueOf(raw.trim().toUpperCase());
    }

    private RolloutActivation parseRolloutActivation(RolloutPolicyDto rollout) {
        if (rollout == null || rollout.activation() == null) {
            return RolloutActivation.IMMEDIATE;
        }
        return RolloutActivation.valueOf(rollout.activation().trim().toUpperCase());
    }

    private Instant parseInstant(String value) {
        return value == null || value.isBlank() ? null : Instant.parse(value);
    }

    private boolean selectorMatches(
            ConfigPackageEntity entity,
            String tenantId,
            String unitId,
            String roleId,
            String userId,
            String deviceId
    ) {
        if (!entity.getTenantId().equals(tenantId)) {
            return false;
        }
        if (entity.getUnitId() != null && !entity.getUnitId().equals(unitId)) {
            return false;
        }
        if (entity.getRoleId() != null && !entity.getRoleId().equals(roleId)) {
            return false;
        }
        if (entity.getUserId() != null && !entity.getUserId().equals(userId)) {
            return false;
        }
        return entity.getDeviceId() == null || entity.getDeviceId().equals(deviceId);
    }

    private boolean rolloutMatches(ConfigPackageEntity entity, String userId) {
        Instant now = Instant.now();
        if (entity.getRolloutActivation() == RolloutActivation.SCHEDULED) {
            if (entity.getRolloutStartsAt() != null && now.isBefore(entity.getRolloutStartsAt())) {
                return false;
            }
            if (entity.getRolloutEndsAt() != null && now.isAfter(entity.getRolloutEndsAt())) {
                return false;
            }
        }

        List<String> batchUsers = splitCsv(entity.getBatchUserIdsCsv());
        return batchUsers.isEmpty() || (userId != null && batchUsers.contains(userId));
    }

    private int scopeRank(ConfigScope scope) {
        return switch (scope) {
            case GLOBAL -> 1;
            case TENANT -> 2;
            case UNIT -> 3;
            case ROLE -> 4;
            case USER -> 5;
            case DEVICE -> 6;
        };
    }

    private List<String> splitCsv(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        return Arrays.stream(value.split(","))
                .map(String::trim)
                .filter(item -> !item.isBlank())
                .toList();
    }

    private static final class ConfigRulesAccumulator {
        private Boolean requireBiometric;
        private Integer cameraMinPhotos;
        private Integer cameraMaxPhotos;
        private Boolean enableVoiceCommands;
        private String theme;
        private String appUpdateChannel;

        private ConfigRulesAccumulator apply(ConfigPackageEntity entity) {
            if (entity.getRequireBiometric() != null) {
                requireBiometric = entity.getRequireBiometric();
            }
            if (entity.getCameraMinPhotos() != null) {
                cameraMinPhotos = entity.getCameraMinPhotos();
            }
            if (entity.getCameraMaxPhotos() != null) {
                cameraMaxPhotos = entity.getCameraMaxPhotos();
            }
            if (entity.getEnableVoiceCommands() != null) {
                enableVoiceCommands = entity.getEnableVoiceCommands();
            }
            if (entity.getTheme() != null) {
                theme = entity.getTheme();
            }
            if (entity.getAppUpdateChannel() != null) {
                appUpdateChannel = entity.getAppUpdateChannel();
            }
            return this;
        }

        private ConfigRulesAccumulator merge(ConfigRulesAccumulator other) {
            return other;
        }

        private ConfigRulesDto toDto() {
            return new ConfigRulesDto(
                    requireBiometric,
                    cameraMinPhotos,
                    cameraMaxPhotos,
                    enableVoiceCommands,
                    theme,
                    appUpdateChannel
            );
        }
    }
}