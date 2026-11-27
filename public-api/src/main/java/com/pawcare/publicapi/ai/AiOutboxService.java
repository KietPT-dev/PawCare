package com.pawcare.publicapi.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/** Writes a deliberately small, non-PII event in the business transaction. */
@Service
public class AiOutboxService {
    private final JdbcTemplate db; private final ObjectMapper json; private final boolean enabled;
    public AiOutboxService(JdbcTemplate db, ObjectMapper json, @Value("${pawcare.ai.enabled:false}") boolean enabled) { this.db=db; this.json=json; this.enabled=enabled; }
    public void enqueue(String type, long id, String event, Map<String,Object> ignoredCallerFeatures) {
        if (!enabled) return;
        try {
            // Only paid deposits currently have a complete, real, non-sensitive feature set.
            // Other callers remain harmless no-ops until their aggregates can supply the same contract.
            if (!"PAYMENT_DEPOSIT".equals(type) || !"PAYMENT_DEPOSIT_PAID".equals(event)) return;
            Map<String,Object> features = paymentDepositFeatures(id);
            if (features == null) return;
            String key=type+":"+id+":"+event+":v1";
            db.update("INSERT IGNORE INTO ai_scoring_outbox(aggregate_type,aggregate_id,event_type,payload_version,feature_snapshot,dedupe_key) VALUES(?,?,?,?,CAST(? AS JSON),?)", type,id,event,1,json.writeValueAsString(features),key);
        } catch (RuntimeException ignored) { /* optional AI must not break money movement */ }
        catch (Exception ignored) { /* serialization is optional too */ }
    }

    private Map<String,Object> paymentDepositFeatures(long depositId) {
        var rows = db.queryForList("""
                SELECT p.amount AS amount, HOUR(p.created_at) AS hourOfDay, DAYOFWEEK(p.created_at)-1 AS dayOfWeek,
                  TIMESTAMPDIFF(DAY,u.created_at,p.created_at) AS accountAgeDays,
                  (SELECT COUNT(*) FROM payment_deposits x WHERE x.user_id=p.user_id AND x.created_at>=DATE_SUB(p.created_at,INTERVAL 10 MINUTE) AND x.created_at<=p.created_at) AS transactionCount10m,
                  (SELECT COUNT(*) FROM payment_deposits x WHERE x.user_id=p.user_id AND x.created_at>=DATE_SUB(p.created_at,INTERVAL 1 HOUR) AND x.created_at<=p.created_at) AS transactionCount1h,
                  (SELECT COUNT(*) FROM payment_deposits x WHERE x.user_id=p.user_id AND x.created_at>=DATE_SUB(p.created_at,INTERVAL 24 HOUR) AND x.created_at<=p.created_at) AS transactionCount24h,
                  (SELECT COALESCE(SUM(x.amount),0) FROM payment_deposits x WHERE x.user_id=p.user_id AND x.created_at>=DATE_SUB(p.created_at,INTERVAL 24 HOUR) AND x.created_at<=p.created_at) AS amountSum24h,
                  (SELECT COUNT(*) FROM payment_deposits x WHERE x.user_id=p.user_id AND x.status='FAILED' AND x.created_at<p.created_at) AS priorFailedAttempts
                FROM payment_deposits p JOIN user_profiles u ON u.id=p.user_id
                WHERE p.id=? AND p.status IN ('PAID','ESCROW_HELD')
                """, depositId);
        if (rows.isEmpty()) return null;
        Map<String,Object> row=rows.get(0); Map<String,Object> out=new LinkedHashMap<>();
        for (String name : AiRiskFeatures.MODEL_FEATURES) {
            Object value=row.get(name); if (!(value instanceof Number) && !(value instanceof BigDecimal)) return null;
            out.put(name, value);
        }
        return out;
    }
}
