package com.appbackoffice.api.integration.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.integration.dto.DemandCreateRequest;
import com.appbackoffice.api.integration.dto.DemandResponse;
import com.appbackoffice.api.integration.entity.IntegrationDemandEntity;
import com.appbackoffice.api.job.dto.CreateCaseRequest;
import com.appbackoffice.api.job.dto.CreateCaseResponse;
import com.appbackoffice.api.job.service.CaseService;
import com.appbackoffice.api.integration.repository.IntegrationDemandRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
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
    private final CaseService caseService;

    public IntegrationDemandService(IntegrationDemandRepository integrationDemandRepository,
                                    IntegrationEventPublisher integrationEventPublisher,
                                    ObjectMapper objectMapper,
                                    CaseService caseService) {
        this.integrationDemandRepository = integrationDemandRepository;
        this.integrationEventPublisher = integrationEventPublisher;
        this.objectMapper = objectMapper;
        this.caseService = caseService;
    }

    @Transactional
    public DemandResponse createOrGet(DemandCreateRequest request) {
        return integrationDemandRepository.findByExternalId(request.externalId())
                .map(existing -> toResponse(ensureCaseAndJobLinked(existing), false))
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
        CreateCaseResponse caseResponse = caseService.createCase(
                request.tenantId(),
                request.requestedBy(),
                toCreateCaseRequest(request)
        );
        saved.setCaseId(caseResponse.caseId());
        saved.setJobId(caseResponse.jobId());
        saved.setStatus("CASE_CREATED");
        saved = integrationDemandRepository.save(saved);
        integrationEventPublisher.publishDemandCreated(saved);
        return toResponse(saved, true);
    }

    @Transactional
    protected IntegrationDemandEntity ensureCaseAndJobLinked(IntegrationDemandEntity entity) {
        if (entity.getCaseId() != null && entity.getJobId() != null) {
            return entity;
        }

        CreateCaseResponse caseResponse = caseService.createCase(
                entity.getTenantId(),
                entity.getRequestedBy(),
                toCreateCaseRequest(entity)
        );
        entity.setCaseId(caseResponse.caseId());
        entity.setJobId(caseResponse.jobId());
        entity.setStatus("CASE_CREATED");
        return integrationDemandRepository.save(entity);
    }

    private CreateCaseRequest toCreateCaseRequest(DemandCreateRequest request) {
        return new CreateCaseRequest(
                buildCaseNumber(request.externalId()),
                formatAddress(request.propertyAddress().street(), request.propertyAddress().city(), request.propertyAddress().state(), request.propertyAddress().zipCode()),
                request.inspectionType(),
                request.requestedDeadline(),
                buildJobTitle(request.externalId(), request.inspectionType())
        );
    }

    private CreateCaseRequest toCreateCaseRequest(IntegrationDemandEntity entity) {
        JsonNode addressNode = readJson(entity.getPropertyAddressJson());
        return new CreateCaseRequest(
                buildCaseNumber(entity.getExternalId()),
                formatAddress(
                        addressNode.path("street").asText(""),
                        addressNode.path("city").asText(""),
                        addressNode.path("state").asText(""),
                        addressNode.path("zipCode").asText("")
                ),
                entity.getInspectionType(),
                entity.getRequestedDeadline(),
                buildJobTitle(entity.getExternalId(), entity.getInspectionType())
        );
    }

    private JsonNode readJson(String value) {
        try {
            return objectMapper.readTree(value);
        } catch (JsonProcessingException e) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "DEMAND_ADDRESS_PARSE_FAILED",
                    "Falha ao interpretar endereco da demanda",
                    ErrorSeverity.ERROR,
                    "Revise o endereco normalizado da demanda e tente novamente.",
                    e.getMessage()
            );
        }
    }

    private String buildCaseNumber(String externalId) {
        return "CASE-" + externalId.trim().replaceAll("[^A-Za-z0-9-]", "-");
    }

    private String buildJobTitle(String externalId, String inspectionType) {
        return "Vistoria " + inspectionType + " - " + externalId;
    }

    private String formatAddress(String street, String city, String state, String zipCode) {
        return String.join(", ", street, city, state, zipCode);
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
                entity.getCaseId(),
                entity.getJobId(),
                created,
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }
}
