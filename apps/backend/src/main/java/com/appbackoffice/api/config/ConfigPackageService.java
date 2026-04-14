package com.appbackoffice.api.config;

import com.appbackoffice.api.config.dto.*;
import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.observability.OperationalEventRecorder;
import com.appbackoffice.api.observability.RequestTracingFilter;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.MDC;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@Transactional
public class ConfigPackageService {

    private final ConfigPackageRepository configPackageRepository;
    private final ConfigAuditEntryRepository configAuditEntryRepository;
    private final ConfigPolicyService configPolicyService;
    private final ConfigPackageApplicationStatusRepository applicationStatusRepository;
    private final ObjectMapper objectMapper;
    private final OperationalEventRecorder operationalEventRecorder;

    public ConfigPackageService(
            ConfigPackageRepository configPackageRepository,
            ConfigAuditEntryRepository configAuditEntryRepository,
            ConfigPolicyService configPolicyService,
            ConfigPackageApplicationStatusRepository applicationStatusRepository,
            ObjectMapper objectMapper,
            OperationalEventRecorder operationalEventRecorder
    ) {
        this.configPackageRepository = configPackageRepository;
        this.configAuditEntryRepository = configAuditEntryRepository;
        this.configPolicyService = configPolicyService;
        this.applicationStatusRepository = applicationStatusRepository;
        this.objectMapper = objectMapper;
        this.operationalEventRecorder = operationalEventRecorder;
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
        recordMutationEvent("CONFIG_PACKAGE_PUBLISHED", "backoffice.config.packages", "SUCCESS", created, request.actorId());

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
        recordMutationEvent("CONFIG_PACKAGE_APPROVED", "backoffice.config.approve", "SUCCESS", updated, request.actorId());
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
        recordMutationEvent("CONFIG_PACKAGE_ROLLED_BACK", "backoffice.config.rollback", "WARNING", updated, request.actorId());
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

        return resolveInternal(tenantId, unitId, roleId, userId, deviceId);
        }

        @Transactional(readOnly = true)
        public ConfigResolveResponse resolveForMobile(String tenantId, String userId, String deviceId) {
        return resolveInternal(tenantId, null, null, userId, deviceId);
        }

        private ConfigResolveResponse resolveInternal(
            String tenantId,
            String unitId,
            String roleId,
            String userId,
            String deviceId
        ) {
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

        ConfigRulesAccumulator accumulator = new ConfigRulesAccumulator();
        for (ConfigPackageEntity entry : applied) {
            accumulator.apply(
                    entry,
                    parseCheckinSections(entry.getCheckinSectionsJson()),
                    parseJsonMap(entry.getStep1Json()),
                    parseJsonMap(entry.getStep2Json()),
                    parseJsonMap(entry.getCameraJson())
            );
        }
        ConfigRulesDto effective = accumulator.toDto();

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

    public ConfigPackageApplicationStatusResponse recordApplicationStatus(
            String tenantId,
            String actorId,
            ConfigPackageApplicationStatusRequest request
    ) {
        ConfigPackageApplicationStatusEntity entity = new ConfigPackageApplicationStatusEntity();
        entity.setTenantId(tenantId);
        entity.setActorId(actorId);
        entity.setPackageId(trimToNull(request.packageId()));
        entity.setPackageVersion(trimRequired(request.packageVersion()));
        entity.setDeviceId(trimToNull(request.deviceId()));
        entity.setAppVersion(trimToNull(request.appVersion()));
        entity.setPlatform(trimToNull(request.platform()));
        entity.setStatus(parseApplicationStatus(request.status()));
        entity.setMessage(trimToNull(request.message()));
        entity.setAppliedAt(Instant.now());

        ConfigPackageApplicationStatusEntity saved = applicationStatusRepository.save(entity);
        recordApplicationStatusEvent(saved);
        return toApplicationStatusResponse(saved);
    }

    @Transactional(readOnly = true)
    public ConfigPackageApplicationStatusesResponse listApplicationStatuses(
            String tenantId,
            String packageVersion,
            ActorRole actorRole
    ) {
        configPolicyService.assertAllowed(actorRole, ConfigAction.READ);
        List<ConfigPackageApplicationStatusEntity> statuses = trimToNull(packageVersion) == null
                ? applicationStatusRepository.findTop100ByTenantIdOrderByUpdatedAtDescIdDesc(tenantId)
                : applicationStatusRepository.findTop100ByTenantIdAndPackageVersionOrderByUpdatedAtDescIdDesc(
                        tenantId,
                        packageVersion.trim()
                );
        List<ConfigPackageApplicationStatusResponse> items = statuses.stream()
                .map(this::toApplicationStatusResponse)
                .toList();
        return new ConfigPackageApplicationStatusesResponse(items, items.size(), Instant.now().toString());
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

    private void recordMutationEvent(String eventType,
                                     String endpointKey,
                                     String outcome,
                                     ConfigPackageEntity entity,
                                     String actorId) {
        operationalEventRecorder.recordDomainEvent(
                entity.getTenantId(),
                "BACKOFFICE",
                eventType,
                endpointKey,
                outcome,
                actorId,
                MDC.get(RequestTracingFilter.CORRELATION_ID_MDC_KEY),
                MDC.get(RequestTracingFilter.TRACE_ID_MDC_KEY),
                null,
                null,
                null,
                null,
                false,
                "Config package mutation recorded",
                java.util.Map.of(
                        "packageId", entity.getId(),
                        "status", entity.getStatus().name(),
                        "scope", entity.getScope().name()
                )
        );
    }

    private void recordApplicationStatusEvent(ConfigPackageApplicationStatusEntity entity) {
        operationalEventRecorder.recordDomainEvent(
                entity.getTenantId(),
                "MOBILE",
                "CONFIG_PACKAGE_" + entity.getStatus().name(),
                "mobile.config-package-status",
                entity.getStatus() == ConfigPackageApplicationStatus.APPLIED ? "SUCCESS" : "WARNING",
                entity.getActorId(),
                MDC.get(RequestTracingFilter.CORRELATION_ID_MDC_KEY),
                MDC.get(RequestTracingFilter.TRACE_ID_MDC_KEY),
                null,
                null,
                null,
                null,
                false,
                "Mobile config package application status recorded",
                java.util.Map.of(
                        "packageId", entity.getPackageId() != null ? entity.getPackageId() : "",
                        "packageVersion", entity.getPackageVersion(),
                        "deviceId", entity.getDeviceId() != null ? entity.getDeviceId() : "",
                        "appVersion", entity.getAppVersion() != null ? entity.getAppVersion() : "",
                        "platform", entity.getPlatform() != null ? entity.getPlatform() : "",
                        "status", entity.getStatus().name()
                )
        );
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
                        entity.getAppUpdateChannel(),
                        parseCheckinSections(entity.getCheckinSectionsJson()),
                        parseJsonMap(entity.getStep1Json()),
                        parseJsonMap(entity.getStep2Json()),
                        parseJsonMap(entity.getCameraJson())
                )
        );
    }

    private ConfigPackageApplicationStatusResponse toApplicationStatusResponse(ConfigPackageApplicationStatusEntity entity) {
        return new ConfigPackageApplicationStatusResponse(
                entity.getId(),
                entity.getTenantId(),
                entity.getPackageId(),
                entity.getPackageVersion(),
                entity.getActorId(),
                entity.getDeviceId(),
                entity.getAppVersion(),
                entity.getPlatform(),
                entity.getStatus().name().toLowerCase(),
                entity.getMessage(),
                entity.getAppliedAt().toString(),
                entity.getUpdatedAt().toString()
        );
    }

    private void applyRules(ConfigPackageEntity entity, ConfigRulesDto rules) {
        entity.setRequireBiometric(rules.requireBiometric());
        entity.setCameraMinPhotos(rules.cameraMinPhotos());
        entity.setCameraMaxPhotos(rules.cameraMaxPhotos());
        entity.setEnableVoiceCommands(rules.enableVoiceCommands());
        entity.setTheme(rules.theme());
        entity.setAppUpdateChannel(rules.appUpdateChannel());
        entity.setCheckinSectionsJson(serializeCheckinSections(rules.checkinSections()));
        entity.setStep1Json(serializeJsonMap(rules.step1(), "step1"));
        entity.setStep2Json(serializeJsonMap(rules.step2(), "step2"));
        entity.setCameraJson(serializeJsonMap(rules.camera(), "camera"));
    }

    private ActorRole parseActorRole(String raw) {
        return ActorRole.valueOf(raw.trim().toUpperCase());
    }

    private ConfigPackageApplicationStatus parseApplicationStatus(String raw) {
        try {
            return ConfigPackageApplicationStatus.valueOf(raw.trim().toUpperCase());
        } catch (Exception exception) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CONFIG_APPLICATION_STATUS_INVALID",
                    "Status de aplicacao de pacote invalido",
                    ErrorSeverity.ERROR,
                    "Informe status APPLIED ou REJECTED.",
                    "status=" + raw
            );
        }
    }

    private String trimRequired(String value) {
        String normalized = trimToNull(value);
        if (normalized == null) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CONFIG_APPLICATION_VERSION_REQUIRED",
                    "Versao do pacote aplicada e obrigatoria",
                    ErrorSeverity.ERROR,
                    "Envie packageVersion no ACK/NACK do pacote.",
                    "field=packageVersion"
            );
        }
        return normalized;
    }

    private String trimToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
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

    private List<ConfigCheckinSectionRuleDto> parseCheckinSections(String raw) {
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(raw, new TypeReference<>() {});
        } catch (Exception exception) {
            return List.of();
        }
    }

    private Map<String, Object> parseJsonMap(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readValue(raw, new TypeReference<>() {});
        } catch (Exception exception) {
            return null;
        }
    }

    private String serializeCheckinSections(List<ConfigCheckinSectionRuleDto> sections) {
        if (sections == null || sections.isEmpty()) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(sections);
        } catch (Exception exception) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CONFIG_RULES_INVALID",
                    "checkinSections invalido para serializacao",
                    ErrorSeverity.ERROR,
                    "Revise a estrutura de rules.checkinSections antes de publicar.",
                    null
            );
        }
    }

    private String serializeJsonMap(Map<String, Object> value, String fieldName) {
        if (value == null || value.isEmpty()) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception exception) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CONFIG_RULES_INVALID",
                    fieldName + " invalido para serializacao",
                    ErrorSeverity.ERROR,
                    "Revise a estrutura de rules." + fieldName + " antes de publicar.",
                    null
            );
        }
    }

    private static final class ConfigRulesAccumulator {
        private Boolean requireBiometric;
        private Integer cameraMinPhotos;
        private Integer cameraMaxPhotos;
        private Boolean enableVoiceCommands;
        private String theme;
        private String appUpdateChannel;
        private List<ConfigCheckinSectionRuleDto> checkinSections;
        private Map<String, Object> step1;
        private Map<String, Object> step2;
        private Map<String, Object> camera;

        private ConfigRulesAccumulator apply(
                ConfigPackageEntity entity,
                List<ConfigCheckinSectionRuleDto> parsedCheckinSections,
                Map<String, Object> parsedStep1,
                Map<String, Object> parsedStep2,
                Map<String, Object> parsedCamera
        ) {
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
            if (parsedCheckinSections != null && !parsedCheckinSections.isEmpty()) {
                checkinSections = parsedCheckinSections;
            }
            if (parsedStep1 != null) {
                step1 = mergeMaps(step1, parsedStep1);
            }
            if (parsedStep2 != null) {
                step2 = mergeMaps(step2, parsedStep2);
            }
            if (parsedCamera != null) {
                camera = mergeMaps(camera, parsedCamera);
            }
            return this;
        }

        private ConfigRulesDto toDto() {
            return new ConfigRulesDto(
                    requireBiometric,
                    cameraMinPhotos,
                    cameraMaxPhotos,
                    enableVoiceCommands,
                    theme,
                    appUpdateChannel,
                    checkinSections,
                    step1,
                    step2,
                    camera
            );
        }

        private Map<String, Object> mergeMaps(Map<String, Object> base, Map<String, Object> incoming) {
            if (base == null || base.isEmpty()) {
                return deepCopy(incoming);
            }
            Map<String, Object> merged = deepCopy(base);
            for (Map.Entry<String, Object> entry : incoming.entrySet()) {
                Object current = merged.get(entry.getKey());
                Object next = entry.getValue();
                if (current instanceof Map<?, ?> currentMap && next instanceof Map<?, ?> nextMap) {
                    merged.put(
                            entry.getKey(),
                            mergeMaps(castToMap(currentMap), castToMap(nextMap))
                    );
                    continue;
                }
                merged.put(entry.getKey(), next);
            }
            return merged;
        }

        @SuppressWarnings("unchecked")
        private Map<String, Object> castToMap(Map<?, ?> value) {
            Map<String, Object> mapped = new LinkedHashMap<>();
            value.forEach((key, item) -> mapped.put(String.valueOf(key), item));
            return mapped;
        }

        private Map<String, Object> deepCopy(Map<String, Object> value) {
            Map<String, Object> copy = new LinkedHashMap<>();
            value.forEach((key, item) -> {
                if (item instanceof Map<?, ?> mapValue) {
                    copy.put(key, deepCopy(castToMap(mapValue)));
                } else {
                    copy.put(key, item);
                }
            });
            return copy;
        }
    }
}
