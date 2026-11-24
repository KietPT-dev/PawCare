package com.pawcare.publicapi.marketplace;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.bonita.BookingWorkflowOutbox;
import com.pawcare.publicapi.location.LocationService;
import com.pawcare.publicapi.media.ProviderCoverService;
import com.pawcare.publicapi.marketplace.dto.BookingStatusRequest;
import com.pawcare.publicapi.marketplace.dto.ReviewReplyRequest;
import com.pawcare.publicapi.wallet.WalletService;
import com.pawcare.publicapi.web.ApiException;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class MarketplaceControllerTest {
    private JdbcTemplate db;
    private MarketplaceController controller;
    private WalletService wallets;

    @BeforeEach
    void setUp() {
        db = mock(JdbcTemplate.class);
        wallets = mock(WalletService.class);
        controller = new MarketplaceController(db, wallets, mock(BookingWorkflowService.class),
                mock(BookingWorkflowOutbox.class), mock(LocationService.class), mock(ProviderCoverService.class));
    }

    @Test
    void providerCatalogueExposesVisibleReviewMetricsAndCreationTime() {
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of());

        controller.providers(null);

        ArgumentCaptor<String> sql = ArgumentCaptor.forClass(String.class);
        verify(db).queryForList(sql.capture(), any(Object[].class));
        assertTrue(sql.getValue().contains("r.is_visible = 1"));
        assertTrue(sql.getValue().contains("review_count"));
        assertTrue(sql.getValue().contains("DATE_FORMAT(p.created_at"));
    }

    @Test
    void nearestCatalogueUsesCustomerCoordinatesAndReturnsDistance() {
        when(db.queryForList(anyString(), any(Object[].class))).thenAnswer(invocation -> {
            String sql = invocation.getArgument(0, String.class);
            if (sql.startsWith("SELECT latitude,longitude")) {
                return List.of(Map.of("latitude", 10.7769, "longitude", 106.7009, "geocode_status", "RESOLVED"));
            }
            return List.of();
        });
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setAttribute("pawcare.principal", customer());

        controller.providers(null, "NEAREST", 0, 20, request, new MockHttpServletResponse());

        ArgumentCaptor<String> sql = ArgumentCaptor.forClass(String.class);
        verify(db, org.mockito.Mockito.times(2)).queryForList(sql.capture(), any(Object[].class));
        assertTrue(sql.getAllValues().get(1).contains("distance_km"));
        assertTrue(sql.getAllValues().get(1).contains("p.geocode_status='RESOLVED'"));
    }

    @Test
    void marksOnlyCurrentUsersUnreadNotificationsAsRead() {
        when(db.update(anyString(), any(Object[].class))).thenReturn(3);

        Map<String, Object> result = controller.readAll(customer());

        assertEquals(true, result.get("success"));
        assertEquals(3, result.get("updated"));
        verify(db).update(anyString(), any(Object[].class));
    }

    @Test
    void providerCanReplyOnlyToOwnReview() {
        when(db.queryForList(anyString(), any(Object[].class))).thenAnswer(invocation -> {
            String sql = invocation.getArgument(0, String.class);
            if (sql.startsWith("SELECT * FROM providers")) return List.of(Map.of("id", 8L));
            if (sql.startsWith("SELECT id,customer_profile_id")) return List.of(Map.of("id", 17L));
            if (sql.startsWith("SELECT id,provider_reply")) {
                return List.of(Map.of("id", 17L, "provider_reply", "Cảm ơn bạn"));
            }
            return List.of();
        });

        Map<String, Object> result = controller.replyToReview(provider(), 17L, new ReviewReplyRequest("  Cảm ơn bạn  "));

        assertEquals("Cảm ơn bạn", result.get("provider_reply"));
        verify(db).update(anyString(), any(Object[].class));
    }

    @Test
    void providerCannotReplyToAnotherProvidersReview() {
        when(db.queryForList(anyString(), any(Object[].class))).thenAnswer(invocation -> {
            String sql = invocation.getArgument(0, String.class);
            return sql.startsWith("SELECT * FROM providers") ? List.of(Map.of("id", 8L)) : List.of();
        });

        ApiException error = assertThrows(ApiException.class,
                () -> controller.replyToReview(provider(), 17L, new ReviewReplyRequest("Cảm ơn")));

        assertEquals(404, error.status());
    }

    @Test
    void customerCanCancelPendingPaymentAndClosesOpenDeposit() {
        when(db.queryForList(anyString(), any(Object[].class))).thenAnswer(invocation -> {
            String sql = invocation.getArgument(0, String.class);
            if (sql.startsWith("SELECT * FROM bookings")) {
                return List.of(Map.of("id", 77L, "status", "PENDING_PAYMENT", "customer_profile_id", 11L,
                        "provider_id", 8L));
            }
            return List.of();
        });

        Map<String, Object> result = controller.bookingStatus(customer(), 77L,
                new BookingStatusRequest("CANCELLED", "Đổi kế hoạch", null, "Khách huỷ trước khi thanh toán"));

        assertEquals("CANCELLED", result.get("status"));
        verify(wallets).releaseEscrowForBooking(77L, "customer cancelled booking");
        verify(db).update("UPDATE payment_deposits SET status='CANCELLED' WHERE booking_id=? AND status='CREATED'", 77L);
    }

    private static CurrentPrincipal customer() {
        return new CurrentPrincipal(11L, "CUSTOMER", "customer@pawcare.test");
    }

    private static CurrentPrincipal provider() {
        return new CurrentPrincipal(22L, "PROVIDER", "provider@pawcare.test");
    }
}
