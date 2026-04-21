package com.appbackoffice.api.mobile.service;

import com.appbackoffice.api.intelligence.entity.FieldEvidenceRecordEntity;
import com.appbackoffice.api.intelligence.entity.InspectionReturnArtifactEntity;
import com.appbackoffice.api.intelligence.service.IntelligenceJsonPayloadMapper;
import com.appbackoffice.api.mobile.dto.InspectionBackofficeDetailResponse;
import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.stereotype.Service;

@Service
public class InspectionArtifactProjectionService {

    private final IntelligenceJsonPayloadMapper jsonPayloadMapper;

    public InspectionArtifactProjectionService(IntelligenceJsonPayloadMapper jsonPayloadMapper) {
        this.jsonPayloadMapper = jsonPayloadMapper;
    }

    public InspectionBackofficeDetailResponse.ReturnArtifact toReturnArtifact(InspectionReturnArtifactEntity entity) {
        return new InspectionBackofficeDetailResponse.ReturnArtifact(
                entity.getExecutionPlanSnapshotId(),
                entity.getRawStorageKey(),
                entity.getNormalizedStorageKey(),
                toPayload(entity.getSummaryJson())
        );
    }

    public InspectionBackofficeDetailResponse.FieldEvidence toFieldEvidence(FieldEvidenceRecordEntity entity) {
        return new InspectionBackofficeDetailResponse.FieldEvidence(
                entity.getSourceSection(),
                entity.getMacroLocation(),
                entity.getEnvironmentName(),
                entity.getElementName(),
                entity.isRequiredFlag(),
                entity.getMinPhotos(),
                entity.getCapturedPhotos(),
                entity.getEvidenceStatus().name(),
                toPayload(entity.getEvidenceJson())
        );
    }

    public JsonNode toPayload(String payloadJson) {
        return jsonPayloadMapper.read(payloadJson);
    }
}
