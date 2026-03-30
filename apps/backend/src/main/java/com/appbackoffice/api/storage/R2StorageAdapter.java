package com.appbackoffice.api.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.net.URI;

/**
 * Adapter para Cloudflare R2 (S3-compatible).
 * Ativado com: storage.adapter=r2
 * A mesma interface funciona para AWS S3 real — basta trocar o endpoint e remover pathStyleAccessEnabled.
 */
@Component
@ConditionalOnProperty(name = "storage.adapter", havingValue = "r2")
public class R2StorageAdapter implements StorageService {

    private final S3Client s3;
    private final String bucket;
    private final String publicBase;

    public R2StorageAdapter(
            @Value("${storage.r2.endpoint}") String endpoint,
            @Value("${storage.r2.access-key}") String accessKey,
            @Value("${storage.r2.secret-key}") String secretKey,
            @Value("${storage.r2.bucket}") String bucket,
            @Value("${storage.r2.public-base:}") String publicBase) {
        this.bucket = bucket;
        this.publicBase = publicBase;
        this.s3 = S3Client.builder()
                .endpointOverride(URI.create(endpoint))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(accessKey, secretKey)))
                .region(Region.of("auto"))
                .serviceConfiguration(S3Configuration.builder()
                        .pathStyleAccessEnabled(true)
                        .build())
                .build();
    }

    @Override
    public StorageResult store(String key, byte[] content, String contentType) {
        s3.putObject(
                PutObjectRequest.builder()
                        .bucket(bucket).key(key)
                        .contentType(contentType)
                        .contentLength((long) content.length)
                        .build(),
                RequestBody.fromBytes(content));
        return new StorageResult(key, getPublicUrl(key), content.length);
    }

    @Override
    public byte[] retrieve(String key) {
        return s3.getObjectAsBytes(
                GetObjectRequest.builder().bucket(bucket).key(key).build()
        ).asByteArray();
    }

    @Override
    public void delete(String key) {
        s3.deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(key).build());
    }

    @Override
    public String getPublicUrl(String key) {
        if (publicBase != null && !publicBase.isBlank()) {
            return publicBase.stripTrailing() + "/" + key;
        }
        return key;
    }
}
