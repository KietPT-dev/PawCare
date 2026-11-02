package com.pawcare.publicapi.wallet;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class WalletServiceWebhookTokenTest {

    @Test
    void removesApiKeySchemeCaseInsensitively() {
        assertEquals("secret-value", WalletService.normalizeWebhookToken("  ApIkEy secret-value  "));
    }

    @Test
    void removesBearerSchemeCaseInsensitively() {
        assertEquals("secret-value", WalletService.normalizeWebhookToken("BEARER secret-value"));
    }

    @Test
    void keepsRawInternalTokenAndHandlesNull() {
        assertEquals("secret-value", WalletService.normalizeWebhookToken(" secret-value "));
        assertEquals("", WalletService.normalizeWebhookToken(null));
    }
}
