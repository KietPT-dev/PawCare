package com.pawcare.publicapi.chat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.pawcare.publicapi.audit.AuditService;
import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.chat.dto.SendChatMessageRequest;
import com.pawcare.publicapi.chat.dto.UpdateConversationReportRequest;
import com.pawcare.publicapi.notification.NotificationService;
import com.pawcare.publicapi.provider.ProviderAccessGuard;
import com.pawcare.publicapi.web.ApiException;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class ChatServiceTest {
    private static final CurrentPrincipal CUSTOMER = new CurrentPrincipal(11L, "CUSTOMER", "customer@pawcare.test");
    private static final CurrentPrincipal OUTSIDER = new CurrentPrincipal(99L, "CUSTOMER", "other@pawcare.test");
    private static final CurrentPrincipal ADMIN = new CurrentPrincipal(1L, "ADMIN", "admin@pawcare.test");

    @Test
    void onlyBookingPartiesCanCreateConversation() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(Map.of("id", 77L, "status", "CONFIRMED", "customer_profile_id", 11L, "provider_profile_id", 22L, "provider_status", "APPROVED", "provider_active", 1)));
        ChatService service = service(db);

        ApiException error = assertThrows(ApiException.class, () -> service.createOrGet(OUTSIDER, 77L));

        assertEquals(403, error.status());
        verify(db, never()).update(anyString(), any(Object[].class));
    }

    @Test
    void duplicateClientMessageReturnsExistingWithoutSendingNotificationAgain() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        Map<String,Object> conversation = Map.of("id", 8L, "status", "OPEN", "customer_profile_id", 11L, "provider_profile_id", 22L);
        Map<String,Object> provider = Map.of("id", 7L, "status", "APPROVED", "is_active", 1);
        Map<String,Object> message = Map.of("id", 91L, "conversation_id", 8L, "sender_profile_id", 11L, "content", "Xin chào");
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(conversation), List.of(provider), List.of(message));
        NotificationService notifications = mock(NotificationService.class);
        ChatService service = new ChatService(db, notifications, mock(AuditService.class), mock(ProviderAccessGuard.class));

        Map<String,Object> result = service.send(CUSTOMER, 8L, new SendChatMessageRequest("Xin chào", "client-1"));

        assertEquals(91L, result.get("id"));
        verify(notifications, never()).notifyOnce(anyLong(), anyString(), anyString(), anyString(), anyString(), anyLong(), anyString());
    }

    @Test
    void onlyAdminCanReadModerationReports() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        ChatService service = service(db);

        ApiException error = assertThrows(ApiException.class, () -> service.reports(CUSTOMER, "OPEN", 0, 20));

        assertEquals(403, error.status());
        verifyNoInteractions(db);
    }

    @Test
    void moderationUpdateWritesMetadataOnlyAudit() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        AuditService audit = mock(AuditService.class);
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(Map.of(
                "id", 4L, "conversation_id", 8L, "status", "OPEN")));
        ChatService service = new ChatService(db, mock(NotificationService.class), audit, mock(ProviderAccessGuard.class));

        Map<String,Object> result = service.updateReport(ADMIN, 4L,
                new UpdateConversationReportRequest("REVIEWED", "Handled"));

        assertEquals("REVIEWED", result.get("status"));
        verify(db, atLeastOnce()).update(anyString(), any(Object[].class));
        verify(audit).record(org.mockito.ArgumentMatchers.eq(1L),
                org.mockito.ArgumentMatchers.eq("CONVERSATION_REPORT_MODERATED"),
                org.mockito.ArgumentMatchers.eq("CONVERSATION_REPORT"), org.mockito.ArgumentMatchers.eq(4L),
                org.mockito.ArgumentMatchers.argThat(details -> !details.containsKey("content")
                        && "OPEN".equals(details.get("oldStatus"))
                        && "REVIEWED".equals(details.get("newStatus"))));
    }

    @Test
    void sameModerationRequestIsIdempotent() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        AuditService audit = mock(AuditService.class);
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(Map.of(
                "id", 4L, "conversation_id", 8L, "status", "REVIEWED", "reviewer_note", "Handled")));
        ChatService service = new ChatService(db, mock(NotificationService.class), audit, mock(ProviderAccessGuard.class));

        Map<String,Object> result = service.updateReport(ADMIN, 4L,
                new UpdateConversationReportRequest("REVIEWED", "Handled"));

        assertEquals(true, result.get("idempotent"));
        verify(db, never()).update(anyString(), any(Object[].class));
        verifyNoInteractions(audit);
    }

    @Test
    void customerCanCreateDirectConversationWithApprovedProvider() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        Map<String,Object> provider = Map.of("id", 8L, "owner_profile_id", 22L, "status", "APPROVED", "is_active", 1);
        Map<String,Object> conversation = Map.of("id", 12L, "conversation_type", "DIRECT", "customer_profile_id", 11L, "provider_profile_id", 22L);
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(provider), List.of(conversation));
        ChatService service = service(db);

        Map<String,Object> result = service.createDirect(CUSTOMER, 8L);

        assertEquals("DIRECT", result.get("conversationType"));
        verify(db, atLeastOnce()).update(anyString(), any(Object[].class));
    }

    @Test
    void providerCannotStartDirectConversationForArbitraryCustomer() {
        ChatService service = service(mock(JdbcTemplate.class));
        CurrentPrincipal provider = new CurrentPrincipal(22L, "PROVIDER", "provider@pawcare.test");

        ApiException error = assertThrows(ApiException.class, () -> service.createDirect(provider, 8L));

        assertEquals(403, error.status());
    }

    @Test
    void customerCannotSendToConversationWhenProviderIsPending() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        Map<String,Object> conversation = Map.of("id", 8L, "status", "OPEN", "customer_profile_id", 11L, "provider_profile_id", 22L);
        Map<String,Object> provider = Map.of("id", 7L, "status", "PENDING", "is_active", 0);
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(conversation), List.of(provider));
        ChatService service = service(db);

        ApiException error = assertThrows(ApiException.class,
                () -> service.send(CUSTOMER, 8L, new SendChatMessageRequest("Xin chào", "client-2")));

        assertEquals(409, error.status());
        assertEquals("PROVIDER_APPROVAL_REQUIRED", error.code());
    }

    private ChatService service(JdbcTemplate db) {
        return new ChatService(db, mock(NotificationService.class), mock(AuditService.class), mock(ProviderAccessGuard.class));
    }
}
