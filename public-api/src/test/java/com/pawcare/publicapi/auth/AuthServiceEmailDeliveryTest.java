package com.pawcare.publicapi.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.pawcare.publicapi.bonita.ProviderApprovalWorkflowOutbox;
import com.pawcare.publicapi.location.LocationService;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

class AuthServiceEmailDeliveryTest {
    @AfterEach
    void clearSynchronization() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    @Test
    void queuesResetDeliveryUntilAfterCommitWithFakeSender() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        CapturingEmailSender sender = new CapturingEmailSender();
        when(db.queryForList(any(String.class), any(Object[].class))).thenAnswer(invocation -> {
            String sql = invocation.getArgument(0, String.class);
            if (sql.contains("FROM user_profiles WHERE email")) {
                return List.of(Map.of("id", 42L, "email", "customer@example.test", "full_name", "Khách hàng"));
            }
            return List.of();
        });

        AuthService service = new AuthService(
                db, mock(JwtService.class), mock(ProviderApprovalWorkflowOutbox.class),
                mock(LocationService.class), sender, 30);
        TransactionSynchronizationManager.initSynchronization();

        assertEquals(true, service.requestPasswordReset("customer@example.test").get("accepted"));
        assertTrue(sender.messages.isEmpty());
        for (TransactionSynchronization synchronization : TransactionSynchronizationManager.getSynchronizations()) {
            synchronization.afterCommit();
        }

        assertEquals(1, sender.messages.size());
        assertEquals("PASSWORD_RESET", sender.messages.get(0).template());
        assertTrue(sender.messages.get(0).textBody().contains("pawcare://auth/reset-password?token="));
    }

    private static final class CapturingEmailSender implements TransactionalEmailSender {
        private final List<TransactionalEmail> messages = new ArrayList<>();
        @Override public void send(TransactionalEmail message) { messages.add(message); }
    }
}
