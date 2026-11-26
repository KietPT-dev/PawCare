package com.pawcare.publicapi.auth;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class AccountEmailFactoryTest {
    @Test
    void resetEmailUsesEncodedAppDeepLinkAndVietnameseSafetyText() {
        TransactionalEmail email = AccountEmailFactory.passwordReset(
                "customer@example.test", "Ngọc", "pawcare://auth", "a+b/c&d");

        assertTrue(email.textBody().contains("pawcare://auth/reset-password?token=a%2Bb%2Fc%26d"));
        assertTrue(email.textBody().contains("30 phút"));
        assertTrue(email.htmlBody().contains("Đặt lại mật khẩu"));
        assertFalse(email.textBody().contains("mật khẩu của bạn là"));
    }

    @Test
    void verificationEmailEscapesDisplayNameInHtml() {
        TransactionalEmail email = AccountEmailFactory.verification(
                "customer@example.test", "<test>", "pawcare://auth/", "token");

        assertTrue(email.htmlBody().contains("&lt;test&gt;"));
        assertTrue(email.textBody().contains("pawcare://auth/verify-email?token=token"));
    }
}
