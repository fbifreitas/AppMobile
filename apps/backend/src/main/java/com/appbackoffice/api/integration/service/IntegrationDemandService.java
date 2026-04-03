package com.appbackoffice.api.integration.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.integration.dto.DemandCreateRequest;
import com.appbackoffice.api.integration.dto.DemandResponse;
import com.appbackoffice.api.integration.entity.IntegrationDemandEntity;
import com.appbackoffice.api.integration.repository.IntegrationDemandRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class IntegrationDemandService {

    private final IntegrationDemandRepository integrationDemandRepository;
    private final IntegrationEventPublisher integrationEventPublisher;
    private final ObjectMapper objectMapper;

    public IntegrationDemandService(IntegrationDemandRepository integrationDemandRepository,
                                    IntegrationEventPublisher integrationEventPublisher,
                                    ObjectMapper objectMapper) {
        this.integrationDemandRepository = integrationDemandRepository;
        this.integrationEventPublisher = integrationEventPublisher;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public DemandResponse createOrGet(DemandCreateRequest request) {
        return integrationDemandRepository.findByExternalId(request.externalId())
                .map(existing -> toResponse(existing, false))
                .orElseGet(() -> createNew(request));
    }

    @Transactional(readOnly = true)
    public DemandResponse findByExternalId(String externalId, String tenantId) {
        IntegrationDemandEntity demand = integrationDemandRepository.findByExternalIdAndTenantId(externalId, tenantId)
                .orElseThrow(() -> new ApiContractException(
                        HttpStatus.NOT_FOUND,
                        "DEMAND_NOT_FOUND",
                        "Demanda nao encontrada",
                        ErrorSeverity.ERROR,
                        "Verifique o externalId e o tenant informado.",
                        "externalId=" + externalId + ", tenantId=" + tenantId
                ));

        return toResponse(demand, false);
    }

    private DemandResponse createNew(DemandCreateRequest request) {
        IntegrationDemandEntity entity = new IntegrationDemandEntity();
        entity.setExternalId(request.externalId());
        entity.setTenantId(request.tenantId());
        entity.setRequestedBy(request.requestedBy());
        entity.setInspectionType(request.inspectionType());
        entity.setRequestedDeadline(request.requestedDeadline());
        entity.setPropertyAddressJson(toJson(request.propertyAddress()));
        entity.setClientDataJson(request.clientData() == null ? null : toJson(request.clientData()));
        entity.setNormalizedPayload(buildNormalizedPayload(request));
        entity.setStatus("RECEIVED");

        IntegrationDemandEntity saved = integrationDemandRepository.save(entity);
        integrationEventPublisher.publishDemandCreated(saved);
        return toResponse(saved, true);
    }

    private String buildNormalizedPayload(DemandCreateRequest request) {
        Map<String, Object> canonical = new LinkedHashMap<>();
        canonical.put("externalId", request.externalId());
        canonical.put("tenantId", request.tenantId());
        canonical.put("requestedBy", request.requestedBy());
        canonical.put("inspectionType", request.inspectionType());
        canonical.put("requestedDeadline", request.requestedDeadline());
        canonical.put("propertyAddress", request.propertyAddress());
        canonical.put("clientData", request.clientData());
        return toJson(canonical);
    }

    private String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "DEMAND_NORMALIZATION_FAILED",
                    "Falha ao normalizar payload da demanda",
                    ErrorSeverity.ERROR,
                    "Revise o payload enviado e tente novamente.",
                    e.getMessage()
            );
        }
    }

    private DemandResponse toResponse(IntegrationDemandEntity entity, boolean created) {
        return new DemandResponse(
                entity.getId(),
                entity.getExternalId(),
                entity.getTenantId(),
                entity.getStatus(),
                created,
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }
}
