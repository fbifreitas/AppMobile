package com.appbackoffice.api.storage;

/**
 * Abstração de storage.
 * Hoje: LocalStorageAdapter (disco da VPS).
 * Futuro: R2StorageAdapter (Cloudflare R2) — troca de 1 linha de config.
 */
public interface StorageService {
    StorageResult store(String key, byte[] content, String contentType);
    byte[] retrieve(String key);
    void delete(String key);
    String getPublicUrl(String key);
}
