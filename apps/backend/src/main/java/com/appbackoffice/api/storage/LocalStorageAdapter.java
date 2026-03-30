package com.appbackoffice.api.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

@Component
@ConditionalOnProperty(name = "storage.adapter", havingValue = "local", matchIfMissing = true)
public class LocalStorageAdapter implements StorageService {

    private final Path basePath;

    public LocalStorageAdapter(@Value("${storage.local.path:./uploads}") String storagePath) {
        this.basePath = Path.of(storagePath).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.basePath);
        } catch (IOException e) {
            throw new StorageException("Nao foi possivel criar diretorio de storage: " + storagePath, e);
        }
    }

    @Override
    public StorageResult store(String key, byte[] content, String contentType) {
        Path target = resolveSecure(key);
        try {
            Files.createDirectories(target.getParent());
            Files.write(target, content);
            return new StorageResult(key, "/uploads/" + key, content.length);
        } catch (IOException e) {
            throw new StorageException("Falha ao salvar arquivo: " + key, e);
        }
    }

    @Override
    public byte[] retrieve(String key) {
        try {
            return Files.readAllBytes(resolveSecure(key));
        } catch (IOException e) {
            throw new StorageException("Arquivo nao encontrado: " + key, e);
        }
    }

    @Override
    public void delete(String key) {
        try {
            Files.deleteIfExists(resolveSecure(key));
        } catch (IOException e) {
            throw new StorageException("Falha ao deletar arquivo: " + key, e);
        }
    }

    @Override
    public String getPublicUrl(String key) {
        return "/uploads/" + key;
    }

    // Protecao contra path traversal (OWASP A01)
    private Path resolveSecure(String key) {
        if (key == null || key.isBlank()) {
            throw new StorageException("Chave de storage nao pode ser vazia");
        }
        Path resolved = basePath.resolve(key).normalize();
        if (!resolved.startsWith(basePath)) {
            throw new StorageException("Chave invalida: tentativa de path traversal bloqueada");
        }
        return resolved;
    }
}
