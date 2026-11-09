package com.pawcare.publicapi.bonita;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Durable, retryable delivery of business events from PawCare to Bonita. */
@Service
public class BookingWorkflowOutbox {
    private static final Logger log = LoggerFactory.getLogger(BookingWorkflowOutbox.class);
    private final JdbcTemplate db;
    private final ObjectMapper json;
    private final BonitaBookingGateway gateway;
    private final BonitaWorkflowProperties properties;

    public BookingWorkflowOutbox(JdbcTemplate db, ObjectMapper json, BonitaBookingGateway gateway,
                                 BonitaWorkflowProperties properties) {
        this.db = db;
        this.json = json;
        this.gateway = gateway;
        this.properties = properties;
    }

    /** Called inside the same local transaction as the booking state change. */
    public void enqueue(long bookingId, BookingWorkflowEvent event, Map<String, ?> payload) {
        String body;
        try {
            body = json.writeValueAsString(payload == null ? Map.of() : payload);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Cannot serialize Bonita workflow event", e);
        }
        db.update("INSERT INTO booking_workflow_outbox(booking_id,event_type,payload_json,status) VALUES(?,?,CAST(? AS JSON),'PENDING') "
                        + "ON DUPLICATE KEY UPDATE payload_json=VALUES(payload_json),status=IF(status='SENT',status,'PENDING'),last_error=NULL",
                bookingId, event.name(), body);
    }

    @Scheduled(fixedDelayString = "${pawcare.bonita.workflow.retry-delay-ms:15000}")
    public void synchronizePending() {
        if (!properties.isEnabled()) return;
        List<Map<String, Object>> events = db.queryForList(
                "SELECT id,booking_id,event_type FROM booking_workflow_outbox WHERE status IN ('PENDING','FAILED') AND attempts<20 ORDER BY id LIMIT 25");
        for (Map<String, Object> event : events) synchronizeOne(event);
    }

    /** Allows controlled immediate synchronization after an administrator enabled the bridge. */
    public void synchronizeNow(long bookingId) {
        if (!properties.isEnabled()) return;
        for (Map<String, Object> event : db.queryForList(
                "SELECT id,booking_id,event_type FROM booking_workflow_outbox WHERE booking_id=? AND status IN ('PENDING','FAILED') ORDER BY id", bookingId)) {
            synchronizeOne(event);
        }
    }

    @Transactional
    protected void synchronizeOne(Map<String, Object> event) {
        long id = ((Number) event.get("id")).longValue();
        long bookingId = ((Number) event.get("booking_id")).longValue();
        BookingWorkflowEvent type = BookingWorkflowEvent.valueOf(String.valueOf(event.get("event_type")));
        try {
            gateway.synchronize(bookingId, type);
            db.update("UPDATE booking_workflow_outbox SET status='SENT',attempts=attempts+1,last_error=NULL,processed_at=CURRENT_TIMESTAMP WHERE id=?", id);
        } catch (Exception error) {
            String message = error.getMessage() == null ? error.getClass().getSimpleName() : error.getMessage();
            db.update("UPDATE booking_workflow_outbox SET status='FAILED',attempts=attempts+1,last_error=? WHERE id=?", abbreviate(message), id);
            log.warn("Bonita workflow sync failed for booking {} event {}: {}", bookingId, type, message);
        }
    }

    private String abbreviate(String value) { return value.length() > 1000 ? value.substring(0, 1000) : value; }
}
