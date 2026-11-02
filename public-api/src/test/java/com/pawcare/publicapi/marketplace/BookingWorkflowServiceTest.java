package com.pawcare.publicapi.marketplace;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.wallet.WalletService;
import com.pawcare.publicapi.web.ApiException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class BookingWorkflowServiceTest {
    private JdbcTemplate db;
    private WalletService wallets;
    private BookingWorkflowService workflow;

    @BeforeEach
    void setUp() {
        db = mock(JdbcTemplate.class);
        wallets = mock(WalletService.class);
        workflow = new BookingWorkflowService(db, wallets);
    }

    @Test
    void providerReportingDoneDoesNotSettleEscrow() {
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(booking("IN_SERVICE")));

        Map<String, Object> result = workflow.providerMarksServiceDone(provider(), 77L, "Đã tắm xong", null);

        assertEquals("SERVICE_DONE", result.get("status"));
        verify(wallets, never()).settleCompletedBooking(anyLong());
        verify(db, atLeast(3)).update(anyString(), any(Object[].class));
    }

    @Test
    void customerConfirmationSettlesOnlyAfterServiceDone() {
        when(db.queryForList(anyString(), any(Object[].class))).thenAnswer(invocation -> {
            String sql = invocation.getArgument(0, String.class);
            return sql.startsWith("SELECT * FROM bookings") ? List.of(booking("SERVICE_DONE"))
                    : List.of(Map.of("owner_profile_id", 22L));
        });

        Map<String, Object> result = workflow.customerConfirmsCompletion(customer(), 77L, "Ổn");

        assertEquals("COMPLETED", result.get("status"));
        verify(wallets).settleCompletedBooking(77L);
        verify(wallets, never()).releaseEscrowForBooking(anyLong(), anyString());
    }

    @Test
    void disputeKeepsEscrowLockedAndCreatesNoPayout() {
        when(db.queryForList(anyString(), any(Object[].class))).thenAnswer(invocation -> {
            String sql = invocation.getArgument(0, String.class);
            if (sql.startsWith("SELECT * FROM bookings")) return List.of(booking("SERVICE_DONE"));
            if (sql.startsWith("SELECT id FROM complaints")) return List.of();
            return List.of(Map.of("owner_profile_id", 22L));
        });
        when(db.queryForObject("SELECT LAST_INSERT_ID()", Long.class)).thenReturn(41L);

        Map<String, Object> result = workflow.customerOpensDispute(customer(), 77L, "Dịch vụ không đúng yêu cầu");

        assertEquals("DISPUTED", result.get("status"));
        assertEquals(41L, result.get("complaintId"));
        verify(wallets, never()).settleCompletedBooking(anyLong());
        verify(wallets, never()).releaseEscrowForBooking(anyLong(), anyString());
    }

    @Test
    void adminRefundResolutionReleasesEscrow() {
        when(db.queryForList(anyString(), any(Object[].class))).thenAnswer(invocation -> {
            String sql = invocation.getArgument(0, String.class);
            return sql.startsWith("SELECT * FROM bookings") ? List.of(booking("DISPUTED"))
                    : List.of(Map.of("owner_profile_id", 22L));
        });

        Map<String, Object> result = workflow.resolveDispute(admin(), 77L, "REFUND_TO_CUSTOMER", "Chấp nhận hoàn tiền");

        assertEquals("CANCELLED", result.get("status"));
        verify(wallets).releaseEscrowForBooking(77L, "admin dispute resolution: refund to customer");
        verify(wallets, never()).settleCompletedBooking(anyLong());
    }

    @Test
    void adminProviderReleaseSettlesEscrow() {
        when(db.queryForList(anyString(), any(Object[].class))).thenAnswer(invocation -> {
            String sql = invocation.getArgument(0, String.class);
            return sql.startsWith("SELECT * FROM bookings") ? List.of(booking("DISPUTED"))
                    : List.of(Map.of("owner_profile_id", 22L));
        });

        Map<String, Object> result = workflow.resolveDispute(admin(), 77L, "RELEASE_TO_PROVIDER", "Đủ bằng chứng hoàn thành");

        assertEquals("COMPLETED", result.get("status"));
        verify(wallets).settleCompletedBooking(77L);
        verify(wallets, never()).releaseEscrowForBooking(anyLong(), anyString());
    }

    @Test
    void customerCannotConfirmBeforeProviderReportsDone() {
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(booking("IN_SERVICE")));

        ApiException error = assertThrows(ApiException.class,
                () -> workflow.customerConfirmsCompletion(customer(), 77L, null));

        assertEquals(409, error.status());
        verifyNoInteractions(wallets);
    }

    private static CurrentPrincipal provider() { return new CurrentPrincipal(22L, "PROVIDER", "provider@pawcare.test"); }
    private static CurrentPrincipal customer() { return new CurrentPrincipal(11L, "CUSTOMER", "customer@pawcare.test"); }
    private static CurrentPrincipal admin() { return new CurrentPrincipal(3L, "ADMIN", "admin@pawcare.test"); }
    private static Map<String, Object> booking(String status) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", 77L); row.put("status", status); row.put("customer_profile_id", 11L); row.put("provider_id", 5L);
        return row;
    }
}
