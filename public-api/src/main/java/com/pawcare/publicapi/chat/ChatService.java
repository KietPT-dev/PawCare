package com.pawcare.publicapi.chat;

import com.pawcare.publicapi.audit.AuditService;
import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.chat.dto.ConversationReportRequest;
import com.pawcare.publicapi.chat.dto.SendChatMessageRequest;
import com.pawcare.publicapi.chat.dto.UpdateConversationReportRequest;
import com.pawcare.publicapi.notification.NotificationService;
import com.pawcare.publicapi.web.ApiException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ChatService {
    private static final Set<String> CHAT_BOOKING_STATUSES = Set.of("PENDING_APPROVAL", "PENDING", "CONFIRMED", "CHECKED_IN", "IN_SERVICE", "SERVICE_DONE", "DISPUTED", "COMPLETED");
    private final JdbcTemplate db;
    private final NotificationService notifications;
    private final AuditService audit;

    public ChatService(JdbcTemplate db, NotificationService notifications, AuditService audit) {
        this.db = db;
        this.notifications = notifications;
        this.audit = audit;
    }

    @Transactional
    public Map<String, Object> createOrGet(CurrentPrincipal principal, long bookingId) {
        Map<String, Object> booking = booking(bookingId);
        authorizeBookingParty(principal, booking);
        if (!CHAT_BOOKING_STATUSES.contains(String.valueOf(booking.get("status")))) {
            throw new ApiException(409, "Chat is unavailable for this booking status");
        }
        db.update("INSERT IGNORE INTO conversations(booking_id,conversation_type,customer_profile_id,provider_profile_id,status) VALUES(?,'BOOKING',?,?,'OPEN')",
                bookingId, booking.get("customer_profile_id"), booking.get("provider_profile_id"));
        Map<String, Object> conversation = conversationByBooking(bookingId);
        ensureReadState(((Number) conversation.get("id")).longValue(), ((Number) booking.get("customer_profile_id")).longValue());
        ensureReadState(((Number) conversation.get("id")).longValue(), ((Number) booking.get("provider_profile_id")).longValue());
        return conversationResponse(conversation);
    }

    @Transactional
    public Map<String, Object> createDirect(CurrentPrincipal principal, long providerId) {
        if (!"CUSTOMER".equals(principal.role())) throw new ApiException(403, "Only Customer accounts can start a direct conversation");
        Map<String,Object> provider = one("SELECT id,owner_profile_id,status,is_active FROM providers WHERE id=?", providerId);
        if (provider == null) throw new ApiException(404, "Provider not found");
        if (!"APPROVED".equals(String.valueOf(provider.get("status"))) || !isActive(provider.get("is_active"))) {
            throw new ApiException(409, "Provider is unavailable for direct chat");
        }
        long providerProfileId = ((Number) provider.get("owner_profile_id")).longValue();
        String directKey = "DIRECT:" + principal.profileId() + ":" + providerProfileId;
        db.update("INSERT IGNORE INTO conversations(booking_id,conversation_type,direct_conversation_key,customer_profile_id,provider_profile_id,status) VALUES(NULL,'DIRECT',?,?,?,'OPEN')",
                directKey, principal.profileId(), providerProfileId);
        Map<String,Object> conversation = one("SELECT * FROM conversations WHERE direct_conversation_key=?", directKey);
        ensureReadState(((Number) conversation.get("id")).longValue(), principal.profileId());
        ensureReadState(((Number) conversation.get("id")).longValue(), providerProfileId);
        return conversationResponse(conversation);
    }

    public List<Map<String, Object>> list(CurrentPrincipal principal, int page, int size) {
        int safePage = Math.max(page, 0), safeSize = Math.min(Math.max(size, 1), 100);
        return db.queryForList("""
                SELECT c.id,c.booking_id,c.booking_id AS bookingId,c.conversation_type AS conversationType,
                       c.status,c.last_message_at,c.created_at,
                       customer.full_name AS customer_name,customer.full_name AS customerName,
                       provider.full_name AS provider_name,provider.full_name AS providerName,
                       latest.content AS last_message,
                       COALESCE(unread.unread_count,0) AS unread_count
                FROM conversations c
                JOIN user_profiles customer ON customer.id=c.customer_profile_id
                JOIN user_profiles provider ON provider.id=c.provider_profile_id
                LEFT JOIN chat_messages latest ON latest.id=(SELECT cm.id FROM chat_messages cm WHERE cm.conversation_id=c.id ORDER BY cm.id DESC LIMIT 1)
                LEFT JOIN (
                    SELECT cm.conversation_id,COUNT(*) unread_count
                    FROM chat_messages cm
                    LEFT JOIN conversation_read_states rs ON rs.conversation_id=cm.conversation_id AND rs.profile_id=?
                    WHERE cm.sender_profile_id<>? AND (rs.last_read_message_id IS NULL OR cm.id>rs.last_read_message_id)
                    GROUP BY cm.conversation_id
                ) unread ON unread.conversation_id=c.id
                WHERE c.customer_profile_id=? OR c.provider_profile_id=?
                ORDER BY COALESCE(c.last_message_at,c.created_at) DESC,c.id DESC
                LIMIT ? OFFSET ?
                """, principal.profileId(), principal.profileId(), principal.profileId(), principal.profileId(), safeSize, (long) safePage * safeSize);
    }

    public List<Map<String, Object>> messages(CurrentPrincipal principal, long conversationId, Long beforeId, int size) {
        requireParticipant(principal, conversationId);
        int safeSize = Math.min(Math.max(size, 1), 100);
        List<Object> args = new ArrayList<>();
        String before = "";
        if (beforeId != null) { before = " AND m.id<?"; args.add(beforeId); }
        args.add(safeSize);
        List<Map<String, Object>> newestFirst = db.queryForList("""
                SELECT m.id,m.conversation_id,m.sender_profile_id,m.content,m.sent_at,m.recalled_at,
                       u.full_name sender_name
                FROM chat_messages m JOIN user_profiles u ON u.id=m.sender_profile_id
                WHERE m.conversation_id=?%s ORDER BY m.id DESC LIMIT ?
                """.formatted(before), prepend(conversationId, args));
        java.util.Collections.reverse(newestFirst);
        return newestFirst;
    }

    @Transactional
    public Map<String, Object> send(CurrentPrincipal principal, long conversationId, SendChatMessageRequest request) {
        Map<String, Object> conversation = requireParticipant(principal, conversationId);
        if (!"OPEN".equals(String.valueOf(conversation.get("status")))) throw new ApiException(409, "Conversation is closed");
        String content = request.content().trim();
        if (content.isBlank()) throw new ApiException(400, "content must not be blank");
        Map<String, Object> existing = one("SELECT id,conversation_id,sender_profile_id,content,sent_at,recalled_at FROM chat_messages WHERE conversation_id=? AND sender_profile_id=? AND client_message_id=?",
                conversationId, principal.profileId(), request.clientMessageId().trim());
        if (existing != null) return existing;
        try {
            db.update("INSERT INTO chat_messages(conversation_id,sender_profile_id,client_message_id,content) VALUES(?,?,?,?)",
                    conversationId, principal.profileId(), request.clientMessageId().trim(), content);
        } catch (DuplicateKeyException ignored) {
            return one("SELECT id,conversation_id,sender_profile_id,content,sent_at,recalled_at FROM chat_messages WHERE conversation_id=? AND sender_profile_id=? AND client_message_id=?",
                    conversationId, principal.profileId(), request.clientMessageId().trim());
        }
        long messageId = lastId();
        db.update("UPDATE conversations SET last_message_at=CURRENT_TIMESTAMP WHERE id=?", conversationId);
        long recipient = otherParticipant(conversation, principal.profileId());
        notifications.notifyOnce(recipient, "Tin nhắn mới", "Bạn có một tin nhắn mới về lịch hẹn.", "CHAT_MESSAGE", "CONVERSATION", conversationId, "chat-message:" + messageId);
        return one("SELECT id,conversation_id,sender_profile_id,content,sent_at,recalled_at FROM chat_messages WHERE id=?", messageId);
    }

    @Transactional
    public Map<String, Object> markRead(CurrentPrincipal principal, long conversationId) {
        requireParticipant(principal, conversationId);
        Long latest = db.queryForObject("SELECT MAX(id) FROM chat_messages WHERE conversation_id=?", Long.class, conversationId);
        ensureReadState(conversationId, principal.profileId());
        db.update("UPDATE conversation_read_states SET last_read_message_id=?,last_read_at=CURRENT_TIMESTAMP WHERE conversation_id=? AND profile_id=?",
                latest, conversationId, principal.profileId());
        Map<String,Object> result = new java.util.LinkedHashMap<>();
        result.put("success", true); result.put("conversationId", conversationId); result.put("lastReadMessageId", latest);
        return result;
    }

    @Transactional
    public Map<String, Object> report(CurrentPrincipal principal, long conversationId, ConversationReportRequest request) {
        requireParticipant(principal, conversationId);
        db.update("INSERT INTO conversation_reports(conversation_id,reporter_profile_id,category,note) VALUES(?,?,?,?)",
                conversationId, principal.profileId(), request.category().trim().toUpperCase(), blankToNull(request.note()));
        long reportId = lastId();
        audit.record(principal.profileId(), "CONVERSATION_REPORTED", "CONVERSATION_REPORT", reportId, Map.of("conversationId", conversationId, "category", request.category().trim().toUpperCase()));
        return Map.of("success", true, "id", reportId, "status", "OPEN");
    }

    public Map<String, Object> reports(CurrentPrincipal principal, String status, int page, int size) {
        requireAdmin(principal);
        int safePage = Math.max(page, 0), safeSize = Math.min(Math.max(size, 1), 100);
        String selected = normalizeReportStatus(status == null || status.isBlank() ? "OPEN" : status);
        Long total = db.queryForObject("SELECT COUNT(*) FROM conversation_reports WHERE status=?", Long.class, selected);
        List<Map<String, Object>> content = db.queryForList("""
                SELECT r.id AS report_id,r.conversation_id,r.category,r.note,r.status,r.created_at,
                       r.reviewed_at,r.reviewer_note,c.booking_id,
                       reporter.id AS reporter_profile_id,reporter.full_name AS reporter_name,
                       reporter.role_code AS reporter_role,
                       customer.id AS customer_profile_id,customer.full_name AS customer_name,
                       provider_profile.id AS provider_profile_id,
                       COALESCE(provider.name,provider_profile.full_name) AS provider_name,
                       reviewer.id AS reviewer_profile_id,reviewer.full_name AS reviewer_name
                FROM conversation_reports r
                JOIN conversations c ON c.id=r.conversation_id
                JOIN user_profiles reporter ON reporter.id=r.reporter_profile_id
                JOIN user_profiles customer ON customer.id=c.customer_profile_id
                JOIN user_profiles provider_profile ON provider_profile.id=c.provider_profile_id
                LEFT JOIN providers provider ON provider.owner_profile_id=c.provider_profile_id
                LEFT JOIN user_profiles reviewer ON reviewer.id=r.reviewed_by_profile_id
                WHERE r.status=? ORDER BY r.created_at ASC,r.id ASC LIMIT ? OFFSET ?
                """, selected, safeSize, (long) safePage * safeSize);
        long totalElements = total == null ? 0L : total;
        Map<String,Object> response = new java.util.LinkedHashMap<>();
        response.put("content", content);
        response.put("page", safePage);
        response.put("size", safeSize);
        response.put("totalElements", totalElements);
        response.put("totalPages", totalElements == 0 ? 0 : (totalElements + safeSize - 1) / safeSize);
        return response;
    }

    @Transactional
    public Map<String, Object> updateReport(CurrentPrincipal principal, long reportId, UpdateConversationReportRequest request) {
        requireAdmin(principal);
        Map<String,Object> report = one("SELECT id,conversation_id,status,reviewer_note FROM conversation_reports WHERE id=?", reportId);
        if (report == null) throw new ApiException(404, "Conversation report not found");
        String requestedStatus = normalizeReportStatus(request.status());
        String requestedNote = blankToNull(request.reviewerNote());
        String oldStatus = String.valueOf(report.get("status"));
        String oldNote = report.get("reviewer_note") == null ? null : String.valueOf(report.get("reviewer_note"));
        if (requestedStatus.equals(oldStatus) && Objects.equals(requestedNote, oldNote)) {
            return reportResponse(reportId, ((Number) report.get("conversation_id")).longValue(), requestedStatus, requestedNote, true);
        }
        if ("OPEN".equals(requestedStatus)) {
            db.update("UPDATE conversation_reports SET status='OPEN',reviewed_by_profile_id=NULL,reviewed_at=NULL,reviewer_note=? WHERE id=?", requestedNote, reportId);
        } else {
            db.update("UPDATE conversation_reports SET status=?,reviewed_by_profile_id=?,reviewed_at=CURRENT_TIMESTAMP,reviewer_note=? WHERE id=?",
                    requestedStatus, principal.profileId(), requestedNote, reportId);
        }
        long conversationId = ((Number) report.get("conversation_id")).longValue();
        audit.record(principal.profileId(), "CONVERSATION_REPORT_MODERATED", "CONVERSATION_REPORT", reportId,
                Map.of("conversationId", conversationId, "oldStatus", oldStatus, "newStatus", requestedStatus));
        return reportResponse(reportId, conversationId, requestedStatus, requestedNote, false);
    }

    @Transactional
    public List<Map<String, Object>> reportedMessages(CurrentPrincipal principal, long conversationId, Long beforeId, int size) {
        requireAdmin(principal);
        if (one("SELECT id FROM conversation_reports WHERE conversation_id=?", conversationId) == null) throw new ApiException(403, "Conversation is not reported");
        List<Map<String, Object>> result = adminMessages(conversationId, beforeId, size);
        audit.record(principal.profileId(), "CONVERSATION_REPORTED_VIEWED", "CONVERSATION", conversationId, Map.of("messageCount", result.size()));
        return result;
    }

    private List<Map<String, Object>> adminMessages(long conversationId, Long beforeId, int size) {
        int safeSize = Math.min(Math.max(size, 1), 100);
        List<Object> args = new ArrayList<>(); String before = "";
        if (beforeId != null) { before = " AND m.id<?"; args.add(beforeId); }
        args.add(safeSize);
        List<Map<String, Object>> result = db.queryForList("SELECT m.id,m.conversation_id,m.sender_profile_id,m.content,m.sent_at,m.recalled_at,u.full_name sender_name FROM chat_messages m JOIN user_profiles u ON u.id=m.sender_profile_id WHERE m.conversation_id=?%s ORDER BY m.id DESC LIMIT ?".formatted(before), prepend(conversationId, args));
        java.util.Collections.reverse(result); return result;
    }

    private Map<String, Object> booking(long bookingId) {
        Map<String, Object> booking = one("SELECT b.id,b.status,b.customer_profile_id,p.owner_profile_id provider_profile_id FROM bookings b JOIN providers p ON p.id=b.provider_id WHERE b.id=?", bookingId);
        if (booking == null) throw new ApiException(404, "Booking not found");
        return booking;
    }
    private void authorizeBookingParty(CurrentPrincipal principal, Map<String, Object> booking) {
        long customer = ((Number) booking.get("customer_profile_id")).longValue();
        long provider = ((Number) booking.get("provider_profile_id")).longValue();
        if (!("CUSTOMER".equals(principal.role()) && customer == principal.profileId()) && !("PROVIDER".equals(principal.role()) && provider == principal.profileId())) throw new ApiException(403, "Only this booking's Customer or Provider can chat");
    }
    private Map<String, Object> requireParticipant(CurrentPrincipal principal, long conversationId) {
        Map<String, Object> conversation = one("SELECT * FROM conversations WHERE id=?", conversationId);
        if (conversation == null) throw new ApiException(404, "Conversation not found");
        long customer = ((Number) conversation.get("customer_profile_id")).longValue();
        long provider = ((Number) conversation.get("provider_profile_id")).longValue();
        if (principal.profileId() != customer && principal.profileId() != provider) throw new ApiException(403, "You are not a conversation participant");
        return conversation;
    }
    private Map<String, Object> conversationByBooking(long bookingId) { return one("SELECT * FROM conversations WHERE booking_id=?", bookingId); }
    private Map<String,Object> conversationResponse(Map<String,Object> conversation) {
        Map<String,Object> response = new java.util.LinkedHashMap<>(conversation);
        response.put("bookingId", conversation.get("booking_id"));
        response.put("conversationType", conversation.get("conversation_type"));
        return response;
    }
    private void ensureReadState(long conversationId, long profileId) { db.update("INSERT IGNORE INTO conversation_read_states(conversation_id,profile_id) VALUES(?,?)", conversationId, profileId); }
    private long otherParticipant(Map<String, Object> conversation, long sender) { long customer=((Number) conversation.get("customer_profile_id")).longValue(); return sender == customer ? ((Number) conversation.get("provider_profile_id")).longValue() : customer; }
    private void requireAdmin(CurrentPrincipal principal) { if (!"ADMIN".equals(principal.role())) throw new ApiException(403, "Admin account required"); }
    private String normalizeReportStatus(String status) {
        String normalized = status == null ? "" : status.trim().toUpperCase();
        if (!Set.of("OPEN", "REVIEWED", "DISMISSED").contains(normalized)) throw new ApiException(400, "Unsupported report status");
        return normalized;
    }
    private Map<String,Object> reportResponse(long reportId, long conversationId, String status, String reviewerNote, boolean idempotent) {
        Map<String,Object> response = new java.util.LinkedHashMap<>();
        response.put("id", reportId); response.put("conversationId", conversationId); response.put("status", status);
        response.put("reviewerNote", reviewerNote); response.put("idempotent", idempotent);
        return response;
    }
    private Map<String, Object> one(String sql, Object... args) { List<Map<String,Object>> rows=db.queryForList(sql,args); return rows.isEmpty()?null:rows.get(0); }
    private long lastId() { Long id=db.queryForObject("SELECT LAST_INSERT_ID()", Long.class); return id == null ? 0L : id; }
    private Object[] prepend(Object first, List<Object> rest) { List<Object> values=new ArrayList<>(); values.add(first); values.addAll(rest); return values.toArray(); }
    private String blankToNull(String value) { return value == null || value.isBlank() ? null : value.trim(); }
    private boolean isActive(Object value) {
        return Boolean.TRUE.equals(value) || value instanceof Number number && number.intValue() == 1;
    }
}
