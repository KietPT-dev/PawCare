package com.pawcare.publicapi.chat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.pawcare.publicapi.audit.AuditService;
import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.chat.dto.SendChatMessageRequest;
import com.pawcare.publicapi.notification.NotificationService;
import com.pawcare.publicapi.web.ApiException;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class ChatServiceTest {
    private static final CurrentPrincipal CUSTOMER = new CurrentPrincipal(11L, "CUSTOMER", "customer@pawcare.test");
    private static final CurrentPrincipal OUTSIDER = new CurrentPrincipal(99L, "CUSTOMER", "other@pawcare.test");

    @Test
    void onlyBookingPartiesCanCreateConversation() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(Map.of("id", 77L, "status", "CONFIRMED", "customer_profile_id", 11L, "provider_profile_id", 22L)));
        ChatService service = service(db);

        ApiException error = assertThrows(ApiException.class, () -> service.createOrGet(OUTSIDER, 77L));

        assertEquals(403, error.status());
        verify(db, never()).update(anyString(), any(Object[].class));
    }

    @Test
    void duplicateClientMessageReturnsExistingWithoutSendingNotificationAgain() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        Map<String,Object> conversation = Map.of("id", 8L, "status", "OPEN", "customer_profile_id", 11L, "provider_profile_id", 22L);
        Map<String,Object> message = Map.of("id", 91L, "conversation_id", 8L, "sender_profile_id", 11L, "content", "Xin chào");
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(conversation), List.of(message));
        NotificationService notifications = mock(NotificationService.class);
        ChatService service = new ChatService(db, notifications, mock(AuditService.class));

        Map<String,Object> result = service.send(CUSTOMER, 8L, new SendChatMessageRequest("Xin chào", "client-1"));

        assertEquals(91L, result.get("id"));
        verify(notifications, never()).notifyOnce(anyLong(), anyString(), anyString(), anyString(), anyString(), anyLong(), anyString());
    }

    private ChatService service(JdbcTemplate db) {
        return new ChatService(db, mock(NotificationService.class), mock(AuditService.class));
    }
}
