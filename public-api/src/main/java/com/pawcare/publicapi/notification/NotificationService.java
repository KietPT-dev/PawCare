package com.pawcare.publicapi.notification;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/** Inserts user-visible events once, even if an outbox delivery is retried. */
@Service
public class NotificationService {
    private final JdbcTemplate db;

    public NotificationService(JdbcTemplate db) { this.db = db; }

    public void notifyOnce(long recipientProfileId, String title, String content, String type,
                           String referenceType, long referenceId, String dedupeKey) {
        db.update("INSERT IGNORE INTO notifications(recipient_profile_id,title,content,notification_type,reference_type,reference_id,dedupe_key) VALUES(?,?,?,?,?,?,?)",
                recipientProfileId, title, content, type, referenceType, referenceId, dedupeKey);
    }
}
