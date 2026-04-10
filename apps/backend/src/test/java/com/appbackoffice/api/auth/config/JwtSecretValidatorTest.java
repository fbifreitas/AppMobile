package com.appbackoffice.api.auth.config;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtSecretValidatorTest {

    @Test
    void shouldAllowStartupWhenSecretIsConfigured() {
        JwtSecretValidator validator = new JwtSecretValidator();
        ReflectionTestUtils.setField(validator, "jwtSecret", "configured-jwt-secret");
        ReflectionTestUtils.setField(validator, "requireSecret", true);

        assertThatCode(validator::afterPropertiesSet).doesNotThrowAnyException();
    }

    @Test
    void shouldAllowStartupWhenSecretIsNotRequired() {
        JwtSecretValidator validator = new JwtSecretValidator();
        ReflectionTestUtils.setField(validator, "jwtSecret", "");
        ReflectionTestUtils.setField(validator, "requireSecret", false);

        assertThatCode(validator::afterPropertiesSet).doesNotThrowAnyException();
    }

    @Test
    void shouldFailFastWhenSecretIsRequiredAndMissing() {
        JwtSecretValidator validator = new JwtSecretValidator();
        ReflectionTestUtils.setField(validator, "jwtSecret", "");
        ReflectionTestUtils.setField(validator, "requireSecret", true);

        assertThatThrownBy(validator::afterPropertiesSet)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("auth.jwt.secret");
    }
}
