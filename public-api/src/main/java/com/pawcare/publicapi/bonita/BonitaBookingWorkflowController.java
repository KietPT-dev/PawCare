package com.pawcare.publicapi.bonita;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.auth.CurrentUser;
import com.pawcare.publicapi.web.ApiException;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Back-office observability/retry endpoints; never exposed to customer/provider UI. */
@RestController
@RequestMapping("/api/v1/admin/bookings")
public class BonitaBookingWorkflowController {
    private final JdbcTemplate db;
    private final BookingWorkflowOutbox outbox;

    public BonitaBookingWorkflowController(JdbcTemplate db, BookingWorkflowOutbox outbox) {
        this.db = db;
        this.outbox = outbox;
    }

    @GetMapping("/{bookingId}/workflow")
    public Map<String, Object> status(@CurrentUser CurrentPrincipal principal, @PathVariable long bookingId) {
        admin(principal);
        List<Map<String, Object>> booking = db.queryForList(
                "SELECT id,status,bonita_case_id,bonita_process_definition_id FROM bookings WHERE id=?", bookingId);
        if (booking.isEmpty()) throw new ApiException(404, "Booking not found");
        List<Map<String, Object>> events = db.queryForList(
                "SELECT id,event_type,status,attempts,last_error,processed_at,created_at FROM booking_workflow_outbox WHERE booking_id=? ORDER BY id", bookingId);
        return Map.of("booking", booking.get(0), "events", events);
    }

    @PostMapping("/{bookingId}/workflow/retry")
    public Map<String, Object> retry(@CurrentUser CurrentPrincipal principal, @PathVariable long bookingId) {
        admin(principal);
        int reset = db.update("UPDATE booking_workflow_outbox SET status='PENDING',last_error=NULL WHERE booking_id=? AND status='FAILED'", bookingId);
        outbox.synchronizeNow(bookingId);
        return Map.of("success", true, "bookingId", bookingId, "eventsReset", reset);
    }

    private void admin(CurrentPrincipal principal) {
        if (!"ADMIN".equals(principal.role())) throw new ApiException(403, "ADMIN account required");
    }
}
