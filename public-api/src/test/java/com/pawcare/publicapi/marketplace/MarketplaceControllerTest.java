package com.pawcare.publicapi.marketplace;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.bonita.BookingWorkflowOutbox;
import com.pawcare.publicapi.marketplace.dto.ReviewReplyRequest;
import com.pawcare.publicapi.wallet.WalletService;
import com.pawcare.publicapi.web.ApiException;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class MarketplaceControllerTest {
    private JdbcTemplate db;
    private MarketplaceController controller;

    @BeforeEach
    void setUp() {
        db = mock(JdbcTemplate.class);
        controller = new MarketplaceController(db, mock(WalletService.class), mock(BookingWorkflowService.class),
                mock(BookingWorkflowOutbox.class));
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

    private static CurrentPrincipal customer() {
        return new CurrentPrincipal(11L, "CUSTOMER", "customer@pawcare.test");
    }

    private static CurrentPrincipal provider() {
        return new CurrentPrincipal(22L, "PROVIDER", "provider@pawcare.test");
    }
}
