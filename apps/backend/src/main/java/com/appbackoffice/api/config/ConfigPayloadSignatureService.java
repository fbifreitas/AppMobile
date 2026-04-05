package com.appbackoffice.api.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Optional;

@Service
public class ConfigPayloadSignatureService {

    private static final String HMAC_SHA_256 = "HmacSHA256";

    @Value("${integration.config-signing.hmac-key:}")
    private String hmacKey;

    public Optional<String> sign(String payload) {
        if (payload == null || payload.isBlank()) {
            return Optional.empty();
        }
        if (hmacKey == null || hmacKey.isBlank()) {
            return Optional.empty();
        }

        try {
            Mac mac = Mac.getInstance(HMAC_SHA_256);
            mac.init(new SecretKeySpec(hmacKey.getBytes(StandardCharsets.UTF_8), HMAC_SHA_256));
            byte[] digest = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            return Optional.of(Base64.getEncoder().encodeToString(digest));
        } catch (Exception exception) {
            return Optional.empty();
        }
    }

    public String algorithmName() {
        return "hmac-sha256";
    }
}
