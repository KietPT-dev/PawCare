package com.pawcare.publicapi.ai;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class AiOutboxServiceTest {
    @Test void writesCompleteSanitizedPaymentFeaturesWithStableDedupeKey() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        when(db.queryForList(startsWith("SELECT p.amount"), eq(9L))).thenReturn(List.of(Map.of(
                "amount", new BigDecimal("500"), "hourOfDay", 9, "dayOfWeek", 2, "accountAgeDays", 30,
                "transactionCount10m", 1, "transactionCount1h", 2, "transactionCount24h", 3,
                "amountSum24h", new BigDecimal("700"), "priorFailedAttempts", 0)));
        AiOutboxService service = new AiOutboxService(db, new ObjectMapper(), true);
        service.enqueue("PAYMENT_DEPOSIT", 9, "PAYMENT_DEPOSIT_PAID", Map.of("email", "never-used@example.test"));
        verify(db).update(startsWith("INSERT IGNORE INTO ai_scoring_outbox"),
                eq("PAYMENT_DEPOSIT"), eq(9L), eq("PAYMENT_DEPOSIT_PAID"), eq(1),
                argThat((String snapshot) -> !snapshot.contains("email") && !snapshot.contains("bank")),
                eq("PAYMENT_DEPOSIT:9:PAYMENT_DEPOSIT_PAID:v1"));
    }

    @Test void unsupportedAggregateDoesNotEnqueueIncompleteEvent() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        new AiOutboxService(db, new ObjectMapper(), true).enqueue("BOOKING", 9, "BOOKING_FUNDED", Map.of());
        verifyNoInteractions(db);
    }
}
