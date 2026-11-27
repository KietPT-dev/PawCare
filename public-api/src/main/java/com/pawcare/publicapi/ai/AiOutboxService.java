package com.pawcare.publicapi.ai;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/** Writes a deliberately small, non-PII event in the business transaction. */
@Service
public class AiOutboxService {
    private final JdbcTemplate db; private final ObjectMapper json; private final boolean enabled;
    public AiOutboxService(JdbcTemplate db, ObjectMapper json, @Value("${pawcare.ai.enabled:false}") boolean enabled) { this.db=db; this.json=json; this.enabled=enabled; }
    public void enqueue(String type, long id, String event, Map<String,Object> features) {
        if (!enabled) return;
        try {
            String key=type+":"+id+":"+event+":v1";
            db.update("INSERT IGNORE INTO ai_scoring_outbox(aggregate_type,aggregate_id,event_type,payload_version,dedupe_key) VALUES(?,?,?,?,?)", type,id,event,1,key);
        } catch (RuntimeException ignored) { /* optional AI must not break money movement */ }
    }
}
