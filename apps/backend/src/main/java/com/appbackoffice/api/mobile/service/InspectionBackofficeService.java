package com.appbackoffice.api.mobile.service;

import com.appbackoffice.api.intelligence.entity.FieldEvidenceRecordEntity;
import com.appbackoffice.api.intelligence.entity.InspectionReturnArtifactEntity;
import com.appbackoffice.api.intelligence.repository.FieldEvidenceRecordRepository;
import com.appbackoffice.api.intelligence.repository.InspectionReturnArtifactRepository;
import com.appbackoffice.api.mobile.dto.InspectionBackofficeDetailResponse;
import com.appbackoffice.api.mobile.dto.InspectionBackofficeListResponse;
import com.appbackoffice.api.mobile.entity.InspectionEntity;
import com.appbackoffice.api.mobile.repository.InspectionRepository;
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
    private final InspectionReturnArtifactRepository inspectionReturnArtifactRepository;
    private final FieldEvidenceRecordRepository fieldEvidenceRecordRepository;
    private final InspectionArtifactProjectionService inspectionArtifactProjectionService;

    public InspectionBackofficeService(InspectionRepository inspectionRepository,
                                       InspectionReturnArtifactRepository inspectionReturnArtifactRepository,
                                       FieldEvidenceRecordRepository fieldEvidenceRecordRepository,
                                       InspectionArtifactProjectionService inspectionArtifactProjectionService) {
        this.inspectionRepository = inspectionRepository;
        this.inspectionReturnArtifactRepository = inspectionReturnArtifactRepository;
        this.fieldEvidenceRecordRepository = fieldEvidenceRecordRepository;
        this.inspectionArtifactProjectionService = inspectionArtifactProjectionService;
    }

    @Transactional(readOnly = true)
    public InspectionBackofficeListResponse list(String tenantId,
                                                 String status,
                                                 Instant from,
                                                 Instant to,
                                                 Long fieldAgentId,
                                                 int page,
                                                 int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "submittedAt", "id"));

        Specification<InspectionEntity> spec = byTenant(tenantId)
                .and(byStatus(status))
                .and(byFieldAgent(fieldAgentId))
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
                inspection.getFieldAgentId(),
                inspection.getIdempotencyKey(),
                inspection.getProtocolId(),
                inspection.getStatus(),
                inspection.getSubmittedAt(),
                inspection.getUpdatedAt(),
                inspectionArtifactProjectionService.toPayload(inspection.getPayloadJson()),
                inspectionReturnArtifactRepository.findTopByInspectionIdOrderByCreatedAtDesc(inspection.getId())
                        .map(inspectionArtifactProjectionService::toReturnArtifact)
                        .orElse(null),
                fieldEvidenceRecordRepository.findByInspectionIdOrderByCreatedAtAsc(inspection.getId())
                        .stream()
                        .map(inspectionArtifactProjectionService::toFieldEvidence)
                        .toList()
        );
    }

    private InspectionBackofficeListResponse.Item toItem(InspectionEntity entity) {
        InspectionReturnArtifactEntity returnArtifact = inspectionReturnArtifactRepository
                .findTopByInspectionIdOrderByCreatedAtDesc(entity.getId())
                .orElse(null);
        int evidenceCount = fieldEvidenceRecordRepository.findByInspectionIdOrderByCreatedAtAsc(entity.getId()).size();
        return new InspectionBackofficeListResponse.Item(
                entity.getId(),
                entity.getJobId(),
                entity.getFieldAgentId(),
                entity.getProtocolId(),
                entity.getStatus(),
                returnArtifact != null,
                returnArtifact != null ? returnArtifact.getExecutionPlanSnapshotId() : null,
                evidenceCount,
                entity.getSubmittedAt(),
                entity.getUpdatedAt()
        );
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

    private Specification<InspectionEntity> byFieldAgent(Long fieldAgentId) {
        if (fieldAgentId == null) {
            return null;
        }
        return (root, query, cb) -> cb.equal(root.get("fieldAgentId"), fieldAgentId);
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
