package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.dto.OperationalReferenceProfilesResponse;
import com.appbackoffice.api.intelligence.entity.OperationalReferenceProfileEntity;
import com.appbackoffice.api.intelligence.repository.OperationalReferenceProfileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class OperationalReferenceProfilesQueryService {

    private final OperationalReferenceProfileRepository repository;
    private final OperationalReferenceProfileCodec codec;

    public OperationalReferenceProfilesQueryService(OperationalReferenceProfileRepository repository,
                                                    OperationalReferenceProfileCodec codec) {
        this.repository = repository;
        this.codec = codec;
    }

    @Transactional(readOnly = true)
    public OperationalReferenceProfilesResponse list(String tenantId) {
        List<OperationalReferenceProfilesResponse.Item> items = repository
                .findAllByOrderByPriorityWeightDescIdAsc()
                .stream()
                .filter(item -> item.getTenantId() == null || item.getTenantId().isBlank() || item.getTenantId().equalsIgnoreCase(tenantId))
                .map(this::toItem)
                .toList();
        return new OperationalReferenceProfilesResponse(items.size(), items);
    }

    private OperationalReferenceProfilesResponse.Item toItem(OperationalReferenceProfileEntity entity) {
        return new OperationalReferenceProfilesResponse.Item(
                entity.getId(),
                entity.getTenantId(),
                entity.getScopeType().name(),
                entity.getSourceType().name(),
                entity.isActiveFlag(),
                entity.getAssetType(),
                entity.getAssetSubtype(),
                entity.getRefinedAssetSubtype(),
                entity.getPropertyStandard(),
                entity.getRegionState(),
                entity.getRegionCity(),
                entity.getRegionDistrict(),
                entity.getPriorityWeight(),
                entity.getConfidenceScore(),
                entity.getFeedbackCount(),
                entity.getTenantId() != null && !entity.getTenantId().isBlank(),
                codec.readStringList(entity.getCandidateSubtypesJson()),
                codec.readStringList(entity.getPhotoLocationsJson()),
                codec.readComposition(entity.getCompositionJson()).size(),
                entity.getCreatedAt() == null ? null : entity.getCreatedAt().toString(),
                entity.getUpdatedAt() == null ? null : entity.getUpdatedAt().toString()
        );
    }
}
