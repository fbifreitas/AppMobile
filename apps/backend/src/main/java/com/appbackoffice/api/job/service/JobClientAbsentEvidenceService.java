package com.appbackoffice.api.job.service;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import com.appbackoffice.api.job.entity.JobClientAbsentEvidenceEntity;
import com.appbackoffice.api.job.repository.JobClientAbsentEvidenceRepository;
import com.appbackoffice.api.storage.StorageResult;
import com.appbackoffice.api.storage.StorageService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.nio.file.Path;
import java.time.Instant;
import java.util.Base64;
import java.util.Locale;
import java.util.UUID;

@Service
public class JobClientAbsentEvidenceService {

    private final StorageService storageService;
    private final JobClientAbsentEvidenceRepository repository;

    public JobClientAbsentEvidenceService(StorageService storageService,
                                         JobClientAbsentEvidenceRepository repository) {
        this.storageService = storageService;
        this.repository = repository;
    }

    public StoredClientAbsentEvidence store(String tenantId,
                                            Long jobId,
                                            String actorId,
                                            String responderName,
                                            String reason,
                                            ClientAbsentEvidenceCommand evidence) {
        if (responderName == null || responderName.trim().isEmpty()) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CLIENT_ABSENT_RESPONDER_REQUIRED",
                    "Responder name is required when the client is absent",
                    ErrorSeverity.ERROR,
                    "Provide the name of the person who answered at the location before submitting the absent-client flow.",
                    "jobId=" + jobId
            );
        }
        if (evidence == null || evidence.imageBase64() == null || evidence.imageBase64().trim().isEmpty()) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CLIENT_ABSENT_EVIDENCE_REQUIRED",
                    "Evidence photo is required when the client is absent",
                    ErrorSeverity.ERROR,
                    "Capture one evidence photo at the location before submitting the absent-client flow.",
                    "jobId=" + jobId
            );
        }

        byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(evidence.imageBase64().trim());
        } catch (IllegalArgumentException exception) {
            throw new ApiContractException(
                    HttpStatus.BAD_REQUEST,
                    "CLIENT_ABSENT_EVIDENCE_INVALID",
                    "Evidence photo payload is invalid",
                    ErrorSeverity.ERROR,
                    "Send the absent-client evidence image using valid Base64 content.",
                    "jobId=" + jobId
            );
        }

        String sanitizedFileName = sanitizeFileName(evidence.fileName());
        String extension = extensionOf(sanitizedFileName);
        String storageKey = "raw/jobs/%s/client-absent/%s%s".formatted(
                jobId,
                UUID.randomUUID(),
                extension
        );
        String contentType = normalizeContentType(evidence.contentType(), extension);
        StorageResult storageResult = storageService.store(storageKey, bytes, contentType);

        JobClientAbsentEvidenceEntity entity = new JobClientAbsentEvidenceEntity();
        entity.setJobId(jobId);
        entity.setTenantId(tenantId);
        entity.setActorId(actorId);
        entity.setResponderName(responderName.trim());
        entity.setReason(reason);
        entity.setStorageKey(storageResult.key());
        entity.setPublicUrl(storageResult.url());
        entity.setContentType(contentType);
        entity.setCapturedAt(resolveCapturedAt(evidence.capturedAt()));
        entity.setLatitude(evidence.latitude());
        entity.setLongitude(evidence.longitude());
        entity.setAccuracy(evidence.accuracy());
        repository.save(entity);

        return new StoredClientAbsentEvidence(
                storageResult.key(),
                storageResult.url(),
                entity.getCapturedAt(),
                entity.getLatitude(),
                entity.getLongitude(),
                entity.getAccuracy()
        );
    }

    private Instant resolveCapturedAt(String rawCapturedAt) {
        if (rawCapturedAt == null || rawCapturedAt.trim().isEmpty()) {
            return Instant.now();
        }
        try {
            return Instant.parse(rawCapturedAt.trim());
        } catch (Exception ignored) {
            return Instant.now();
        }
    }

    private String sanitizeFileName(String fileName) {
        String normalized = fileName == null ? "" : fileName.trim();
        if (normalized.isEmpty()) {
            return "evidence.jpg";
        }
        return Path.of(normalized).getFileName().toString().replace(' ', '_');
    }

    private String extensionOf(String fileName) {
        int index = fileName.lastIndexOf('.');
        if (index < 0) {
            return ".jpg";
        }
        return fileName.substring(index).toLowerCase(Locale.ROOT);
    }

    private String normalizeContentType(String rawContentType, String extension) {
        if (rawContentType != null && !rawContentType.trim().isEmpty()) {
            return rawContentType.trim();
        }
        return switch (extension) {
            case ".png" -> "image/png";
            case ".webp" -> "image/webp";
            default -> "image/jpeg";
        };
    }

    public record ClientAbsentEvidenceCommand(
            String fileName,
            String contentType,
            String imageBase64,
            String capturedAt,
            Double latitude,
            Double longitude,
            Double accuracy
    ) {
    }

    public record StoredClientAbsentEvidence(
            String storageKey,
            String publicUrl,
            Instant capturedAt,
            Double latitude,
            Double longitude,
            Double accuracy
    ) {
    }
}
