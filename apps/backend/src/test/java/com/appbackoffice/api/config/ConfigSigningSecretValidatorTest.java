package com.appbackoffice.api.config;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ConfigSigningSecretValidatorTest {

    @Test
    void afterPropertiesSet_allowsBlankSecretWhenNotRequired() {
        ConfigSigningSecretValidator validator = new ConfigSigningSecretValidator();
        ReflectionTestUtils.setField(validator, "hmacKey", "");
        ReflectionTestUtils.setField(validator, "requireSecret", false);

        assertThatCode(validator::afterPropertiesSet).doesNotThrowAnyException();
    }

    @Test
    void afterPropertiesSet_failsFastWhenSecretIsRequiredAndMissing() {
        ConfigSigningSecretValidator validator = new ConfigSigningSecretValidator();
        ReflectionTestUtils.setField(validator, "hmacKey", "");
        ReflectionTestUtils.setField(validator, "requireSecret", true);

        assertThatThrownBy(validator::afterPropertiesSet)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("integration.config-signing.hmac-key");
    }

    @Test
    void afterPropertiesSet_acceptsConfiguredSecret() {
        ConfigSigningSecretValidator validator = new ConfigSigningSecretValidator();
        ReflectionTestUtils.setField(validator, "hmacKey", "configured-secret");
        ReflectionTestUtils.setField(validator, "requireSecret", true);

        assertThatCode(validator::afterPropertiesSet).doesNotThrowAnyException();
    }
}
