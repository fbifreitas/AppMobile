package com.appbackoffice.api.mobile.service;

import com.appbackoffice.api.mobile.dto.InspectionBackofficeDetailResponse;
import com.appbackoffice.api.mobile.dto.InspectionBackofficeListResponse;
import com.appbackoffice.api.mobile.entity.InspectionEntity;
import com.appbackoffice.api.mobile.repository.InspectionRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;

@Service
public class InspectionBackofficeService {

    private final InspectionRepository inspectionRepository;
    private final ObjectMapper objectMapper;

    public InspectionBackofficeService(InspectionRepository inspectionRepository, ObjectMapper objectMapper) {
        this.inspectionRepository = inspectionRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public InspectionBackofficeListResponse list(String tenantId,
                                                 String status,
                                                 Instant from,
                                                 Instant to,
                                                 Long vistoriadorId,
                                                 int page,
                                                 int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "submittedAt", "id"));

        Specification<InspectionEntity> spec = byTenant(tenantId)
                .and(byStatus(status))
                .and(byVistoriador(vistoriadorId))
                .and(byFrom(from))
                .and(byTo(to));

        Page<InspectionEntity> result = inspectionRepository.findAll(spec, pageable);
        Instant todayStart = LocalDate.now(ZoneOffset.UTC).atStartOfDay().toInstant(ZoneOffset.UTC);

        return new InspectionBackofficeListResponse(
                result.getNumber(),
                result.getSize(),
                result.getTotalElements(),
            new InspectionBackofficeListResponse.Summary(
                inspectionRepository.count(byTenant(tenantId).and(byFrom(todayStart))),
                inspectionRepository.count(byTenant(tenantId).and(byStatus("RECEIVED"))),
                inspectionRepository.count(byTenant(tenantId).and(byStatus("ERROR"))),
                inspectionRepository.count(byTenant(tenantId).and(byStatus("SUBMITTED")))
            ),
                result.getContent().stream().map(this::toItem).toList()
        );
    }

    @Transactional(readOnly = true)
    public InspectionBackofficeDetailResponse detail(String tenantId, Long inspectionId) {
        InspectionEntity inspection = inspectionRepository.findByIdAndTenantId(inspectionId, tenantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Inspection não encontrada"));

        return new InspectionBackofficeDetailResponse(
                inspection.getId(),
                inspection.getSubmissionId(),
                inspection.getJobId(),
                inspection.getTenantId(),
                inspection.getVistoriadorId(),
                inspection.getIdempotencyKey(),
                inspection.getProtocolId(),
                inspection.getStatus(),
                inspection.getSubmittedAt(),
                inspection.getUpdatedAt(),
                toPayload(inspection.getPayloadJson())
        );
    }

    private InspectionBackofficeListResponse.Item toItem(InspectionEntity entity) {
        return new InspectionBackofficeListResponse.Item(
                entity.getId(),
                entity.getJobId(),
                entity.getVistoriadorId(),
                entity.getProtocolId(),
                entity.getStatus(),
                entity.getSubmittedAt(),
                entity.getUpdatedAt()
        );
    }

    private JsonNode toPayload(String payloadJson) {
        try {
            return objectMapper.readTree(payloadJson);
        } catch (Exception exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Falha ao desserializar payload da inspection");
        }
    }

    private Specification<InspectionEntity> byTenant(String tenantId) {
        return (root, query, cb) -> cb.equal(root.get("tenantId"), tenantId);
    }

    private Specification<InspectionEntity> byStatus(String status) {
        if (status == null || status.isBlank()) {
            return null;
        }
        return (root, query, cb) -> cb.equal(root.get("status"), status.trim().toUpperCase());
    }

    private Specification<InspectionEntity> byVistoriador(Long vistoriadorId) {
        if (vistoriadorId == null) {
            return null;
        }
        return (root, query, cb) -> cb.equal(root.get("vistoriadorId"), vistoriadorId);
    }

    private Specification<InspectionEntity> byFrom(Instant from) {
        if (from == null) {
            return null;
        }
        return (root, query, cb) -> cb.greaterThanOrEqualTo(root.get("submittedAt"), from);
    }

    private Specification<InspectionEntity> byTo(Instant to) {
        if (to == null) {
            return null;
        }
        return (root, query, cb) -> cb.lessThanOrEqualTo(root.get("submittedAt"), to);
    }
}
