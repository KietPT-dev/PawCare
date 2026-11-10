package com.pawcare.publicapi.audit;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/** Append-only audit trail. Callers must pass only non-sensitive business facts. */
@Service
public class AuditService {
    private final JdbcTemplate db;
    private final ObjectMapper json;

    public AuditService(JdbcTemplate db, ObjectMapper json) { this.db = db; this.json = json; }

    public void record(Long actorProfileId, String action, String entityType, Long entityId, Map<String, ?> details) {
        try {
            db.update("INSERT INTO audit_logs(actor_profile_id,action_type,entity_type,entity_id,details_json) VALUES(?,?,?,?,CAST(? AS JSON))",
                    actorProfileId, action, entityType, entityId, json.writeValueAsString(details == null ? Map.of() : details));
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Cannot serialize audit details", e);
        }
    }
}
