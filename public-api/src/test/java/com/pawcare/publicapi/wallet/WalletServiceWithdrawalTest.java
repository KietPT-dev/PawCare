package com.pawcare.publicapi.wallet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.bonita.BookingWorkflowOutbox;
import com.pawcare.publicapi.wallet.dto.WithdrawalDecisionRequest;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class WalletServiceWithdrawalTest {

    private static final CurrentPrincipal ADMIN = new CurrentPrincipal(3L, "ADMIN", "admin@pawcare.local");

    @Test
    void approvalKeepsReservedFundsLockedUntilManualPayout() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        stubWithdrawal(db, "PENDING");
        WalletService service = new WalletService(db, mock(BookingWorkflowOutbox.class), "secret", "MB", "1", "PawCare");

        Map<String, Object> result = service.decideWithdrawal(ADMIN, 9L,
                new WithdrawalDecisionRequest("APPROVED", "verified", null));

        assertEquals("APPROVED", result.get("status"));
        verify(db).update(anyString(), any(Object[].class));
        org.mockito.Mockito.verify(db, org.mockito.Mockito.never())
                .update(org.mockito.ArgumentMatchers.startsWith("UPDATE wallets SET locked_balance=? WHERE id=?"), any(Object[].class));
    }

    @Test
    void paidManualPayoutConsumesOnlyLockedFunds() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        stubWithdrawal(db, "PROCESSING");
        WalletService service = new WalletService(db, mock(BookingWorkflowOutbox.class), "secret", "MB", "1", "PawCare");

        Map<String, Object> result = service.decideWithdrawal(ADMIN, 9L,
                new WithdrawalDecisionRequest("PAID", "reconciled", "BANK-REF-9"));

        assertEquals("PAID", result.get("status"));
        verify(db).update(org.mockito.ArgumentMatchers.startsWith("UPDATE wallets SET locked_balance=? WHERE id=?"), any(Object[].class));
    }

    private void stubWithdrawal(JdbcTemplate db, String status) {
        Map<String, Object> request = Map.of("id", 9L, "wallet_id", 8L, "amount", new BigDecimal("50000.00"), "status", status);
        Map<String, Object> wallet = Map.of("id", 8L, "owner_type", "PROVIDER", "owner_id", 4L,
                "available_balance", new BigDecimal("125000.00"), "locked_balance", new BigDecimal("50000.00"));
        when(db.queryForList(anyString(), any(Object[].class))).thenAnswer(invocation -> {
            String sql = invocation.getArgument(0, String.class);
            if (sql.startsWith("SELECT * FROM withdrawal_requests")) return List.of(request);
            if (sql.startsWith("SELECT * FROM wallets WHERE id")) return List.of(wallet);
            if (sql.startsWith("SELECT owner_profile_id FROM providers")) return List.of(Map.of("owner_profile_id", 15L));
            return List.of();
        });
    }
}
