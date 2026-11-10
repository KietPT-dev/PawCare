package com.pawcare.publicapi.wallet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

import com.pawcare.publicapi.bonita.BookingWorkflowOutbox;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

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

    @Test
    void duplicateBankTransactionReturnsIdempotentResultWithoutMovingMoneyAgain() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        BookingWorkflowOutbox outbox = mock(BookingWorkflowOutbox.class);
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(Map.of(
                "id", 8L, "booking_id", 77L, "status", "ESCROW_HELD")));
        WalletService service = new WalletService(db, outbox, "webhook-secret", "MB", "123", "PawCare");

        Map<String, Object> result = service.processBankWebhook("Bearer webhook-secret", Map.of(
                "referenceCode", "bank-transaction-1", "content", "PAW77", "transferAmount", 50000));

        assertEquals(true, result.get("success"));
        assertEquals(true, result.get("idempotent"));
        assertEquals(8L, result.get("depositId"));
        assertTrue(result.containsKey("status"));
        verify(db, never()).update(anyString(), any(Object[].class));
        verifyNoInteractions(outbox);
    }
}
