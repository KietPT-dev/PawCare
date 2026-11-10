package com.pawcare.publicapi.marketplace;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.audit.AuditService;
import com.pawcare.publicapi.bonita.BookingWorkflowEvent;
import com.pawcare.publicapi.bonita.BookingWorkflowOutbox;
import com.pawcare.publicapi.notification.NotificationService;
import com.pawcare.publicapi.wallet.WalletService;
import com.pawcare.publicapi.web.ApiException;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Owns the two-party completion workflow.  A provider can report work done,
 * but only the customer (or an admin resolving a dispute) can release escrow.
 */
@Service
public class BookingWorkflowService {
    private final JdbcTemplate db;
    private final WalletService wallets;
    private final BookingWorkflowOutbox workflowOutbox;
    private final NotificationService notifications;
    private final AuditService audit;

    public BookingWorkflowService(JdbcTemplate db, WalletService wallets, BookingWorkflowOutbox workflowOutbox,
                                  NotificationService notifications, AuditService audit) {
        this.db = db;
        this.wallets = wallets;
        this.workflowOutbox = workflowOutbox;
        this.notifications = notifications;
        this.audit = audit;
    }

    @Transactional
    public Map<String, Object> providerMarksServiceDone(CurrentPrincipal principal, long bookingId,
                                                         String providerNote, String note) {
        requireRole(principal, "PROVIDER");
        Map<String, Object> booking = one("SELECT b.* FROM bookings b JOIN providers p ON p.id=b.provider_id "
                + "WHERE b.id=? AND p.owner_profile_id=? FOR UPDATE", bookingId, principal.profileId());
        requireStatus(booking, "IN_SERVICE", "Only an in-service booking can be reported as done");
        updateBooking(bookingId, "SERVICE_DONE", providerNote);
        history(bookingId, "IN_SERVICE", "SERVICE_DONE", principal.profileId(), text(note, "Provider reported service completed; waiting for customer confirmation"));
        notifyProfile(longValue(booking, "customer_profile_id"), "Xác nhận hoàn tất dịch vụ",
                "Provider đã báo hoàn tất Booking #" + bookingId + ". Hãy xác nhận hoặc gửi khiếu nại.",
                "BOOKING_COMPLETION", bookingId);
        workflowOutbox.enqueue(bookingId, BookingWorkflowEvent.PROVIDER_SERVICE_DONE, Map.of("providerProfileId", principal.profileId()));
        return Map.of("success", true, "id", bookingId, "status", "SERVICE_DONE");
    }

    @Transactional
    public Map<String, Object> customerConfirmsCompletion(CurrentPrincipal principal, long bookingId, String note) {
        requireRole(principal, "CUSTOMER");
        Map<String, Object> booking = one("SELECT * FROM bookings WHERE id=? AND customer_profile_id=? FOR UPDATE", bookingId, principal.profileId());
        requireStatus(booking, "SERVICE_DONE", "Only a service waiting for confirmation can be completed");
        updateBooking(bookingId, "COMPLETED", null);
        history(bookingId, "SERVICE_DONE", "COMPLETED", principal.profileId(), text(note, "Customer confirmed service completion"));
        wallets.settleCompletedBooking(bookingId);
        Long providerProfileId = providerOwner(longValue(booking, "provider_id"));
        if (providerProfileId != null) {
            notifyProfile(providerProfileId, "Dịch vụ đã được khách xác nhận",
                    "Booking #" + bookingId + " đã hoàn tất. Doanh thu 90% đã được cộng vào ví của bạn.",
                    "BOOKING_COMPLETION", bookingId);
        }
        workflowOutbox.enqueue(bookingId, BookingWorkflowEvent.CUSTOMER_CONFIRMED, Map.of("customerProfileId", principal.profileId()));
        return Map.of("success", true, "id", bookingId, "status", "COMPLETED");
    }

    @Transactional
    public Map<String, Object> customerOpensDispute(CurrentPrincipal principal, long bookingId, String content) {
        requireRole(principal, "CUSTOMER");
        if (content == null || content.isBlank()) throw new ApiException(400, "content is required");
        Map<String, Object> booking = one("SELECT * FROM bookings WHERE id=? AND customer_profile_id=? FOR UPDATE", bookingId, principal.profileId());
        requireStatus(booking, "SERVICE_DONE", "A dispute can only be opened while customer confirmation is pending");
        Map<String, Object> existing = one("SELECT id FROM complaints WHERE booking_id=? AND status IN ('OPEN','IN_PROGRESS') FOR UPDATE", bookingId);
        if (existing != null) throw new ApiException(409, "An unresolved dispute already exists for this booking");
        db.update("UPDATE bookings SET status='DISPUTED' WHERE id=?", bookingId);
        db.update("INSERT INTO complaints(booking_id,customer_profile_id,provider_id,content,status) VALUES(?,?,?,?, 'OPEN')",
                bookingId, principal.profileId(), booking.get("provider_id"), content.trim());
        long complaintId = lastId();
        history(bookingId, "SERVICE_DONE", "DISPUTED", principal.profileId(), "Customer opened dispute #" + complaintId);
        Long providerProfileId = providerOwner(longValue(booking, "provider_id"));
        if (providerProfileId != null) {
            notifyProfile(providerProfileId, "Booking đang có tranh chấp",
                    "Khách hàng đã mở tranh chấp cho Booking #" + bookingId + ". Tiền tiếp tục được giữ trong escrow.",
                    "BOOKING_DISPUTE", bookingId);
        }
        workflowOutbox.enqueue(bookingId, BookingWorkflowEvent.CUSTOMER_DISPUTED, Map.of("customerProfileId", principal.profileId(), "complaintId", complaintId));
        return Map.of("success", true, "id", bookingId, "status", "DISPUTED", "complaintId", complaintId);
    }

    @Transactional
    public Map<String, Object> resolveDispute(CurrentPrincipal principal, long bookingId, String action, String adminNote) {
        requireRole(principal, "ADMIN");
        String decision = action == null ? "" : action.trim().toUpperCase();
        if (!List.of("REFUND_TO_CUSTOMER", "RELEASE_TO_PROVIDER").contains(decision)) {
            throw new ApiException(400, "action must be REFUND_TO_CUSTOMER or RELEASE_TO_PROVIDER");
        }
        Map<String, Object> booking = one("SELECT * FROM bookings WHERE id=? FOR UPDATE", bookingId);
        requireStatus(booking, "DISPUTED", "Only disputed bookings can be resolved by admin");

        String finalStatus = "REFUND_TO_CUSTOMER".equals(decision) ? "CANCELLED" : "COMPLETED";
        db.update("UPDATE bookings SET status=?,cancel_reason=CASE WHEN ?='CANCELLED' THEN ? ELSE cancel_reason END WHERE id=?",
                finalStatus, finalStatus, "Admin refunded disputed booking", bookingId);
        history(bookingId, "DISPUTED", finalStatus, principal.profileId(),
                text(adminNote, "Admin decision: " + decision));
        db.update("UPDATE complaints SET status='RESOLVED',admin_response=?,resolved_at=CURRENT_TIMESTAMP "
                        + "WHERE booking_id=? AND status IN ('OPEN','IN_PROGRESS')",
                text(adminNote, "Admin decision: " + decision), bookingId);

        if ("REFUND_TO_CUSTOMER".equals(decision)) {
            wallets.releaseEscrowForBooking(bookingId, "admin dispute resolution: refund to customer");
        } else {
            wallets.settleCompletedBooking(bookingId);
        }
        audit.record(principal.profileId(), "DISPUTE_" + decision, "BOOKING", bookingId,
                Map.of("decision", decision, "finalStatus", finalStatus));
        String outcome = "REFUND_TO_CUSTOMER".equals(decision)
                ? "Admin đã hoàn tiền escrow cho bạn."
                : "Admin đã xác nhận hoàn tất và giải ngân tiền escrow.";
        notifyProfile(longValue(booking, "customer_profile_id"), "Tranh chấp đã được xử lý",
                "Booking #" + bookingId + ": " + outcome, "BOOKING_DISPUTE", bookingId);
        Long providerProfileId = providerOwner(longValue(booking, "provider_id"));
        if (providerProfileId != null) {
            notifyProfile(providerProfileId, "Tranh chấp đã được xử lý",
                    "Booking #" + bookingId + ": " + outcome, "BOOKING_DISPUTE", bookingId);
        }
        workflowOutbox.enqueue(bookingId,
                "REFUND_TO_CUSTOMER".equals(decision) ? BookingWorkflowEvent.ADMIN_REFUND_TO_CUSTOMER : BookingWorkflowEvent.ADMIN_RELEASE_TO_PROVIDER,
                Map.of("adminProfileId", principal.profileId(), "decision", decision));
        return Map.of("success", true, "id", bookingId, "status", finalStatus, "action", decision);
    }

    private void updateBooking(long bookingId, String status, String providerNote) {
        db.update("UPDATE bookings SET status=?,provider_note=COALESCE(?,provider_note) WHERE id=?", status, providerNote, bookingId);
    }
    private void history(long bookingId, String before, String after, long profileId, String note) {
        db.update("INSERT INTO booking_status_history(booking_id,previous_status,new_status,changed_by_profile_id,note) VALUES(?,?,?,?,?)",
                bookingId, before, after, profileId, note);
    }
    private void notifyProfile(long profileId, String title, String content, String type, long bookingId) {
        notifications.notifyOnce(profileId, title, content, type, "BOOKING", bookingId,
                type + ":" + bookingId + ":" + profileId);
    }
    private Long providerOwner(long providerId) {
        Map<String, Object> provider = one("SELECT owner_profile_id FROM providers WHERE id=?", providerId);
        return provider == null || provider.get("owner_profile_id") == null ? null : longValue(provider, "owner_profile_id");
    }
    private void requireRole(CurrentPrincipal p, String role) {
        if (!role.equals(p.role())) throw new ApiException(403, role + " account required");
    }
    private void requireStatus(Map<String, Object> booking, String expected, String message) {
        if (booking == null) throw new ApiException(404, "Booking not found or not owned by you");
        if (!expected.equals(String.valueOf(booking.get("status")))) throw new ApiException(409, message);
    }
    private Map<String, Object> one(String sql, Object... args) {
        List<Map<String, Object>> rows = db.queryForList(sql, args);
        return rows.isEmpty() ? null : rows.get(0);
    }
    private long lastId() { return db.queryForObject("SELECT LAST_INSERT_ID()", Long.class); }
    private long longValue(Map<String, Object> row, String key) { return ((Number) row.get(key)).longValue(); }
    private String text(String candidate, String fallback) { return candidate == null || candidate.isBlank() ? fallback : candidate.trim(); }
}
