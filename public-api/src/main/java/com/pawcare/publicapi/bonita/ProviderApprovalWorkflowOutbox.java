package com.pawcare.publicapi.bonita;

import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Durable START delivery. Provider state is only changed by the callback from Bonita. */
@Service
public class ProviderApprovalWorkflowOutbox {
    private static final Logger log = LoggerFactory.getLogger(ProviderApprovalWorkflowOutbox.class);
    private final JdbcTemplate db;
    private final BonitaProviderApprovalGateway gateway;
    private final ProviderApprovalWorkflowProperties settings;

    public ProviderApprovalWorkflowOutbox(JdbcTemplate db, BonitaProviderApprovalGateway gateway,
                                          ProviderApprovalWorkflowProperties settings) {
        this.db = db; this.gateway = gateway; this.settings = settings;
    }

    public void enqueueStart(long providerId) {
        db.update("INSERT INTO provider_approval_workflow_outbox(provider_id,event_type,status) VALUES(?,'START','PENDING') "
                        + "ON DUPLICATE KEY UPDATE status=IF(status='SENT',status,'PENDING'),last_error=NULL",
                providerId);
    }

    @Scheduled(fixedDelayString = "${pawcare.bonita.provider-approval.retry-delay-ms:15000}")
    public void synchronizePending() {
        if (!settings.isEnabled()) return;
        for (Map<String,Object> event : db.queryForList("SELECT id,provider_id FROM provider_approval_workflow_outbox "
                + "WHERE (status IN ('PENDING','FAILED') OR (status='PROCESSING' AND locked_at < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 5 MINUTE))) "
                + "AND attempts<20 ORDER BY id LIMIT 25")) synchronizeOne(event);
    }

    public void synchronizeNow(long providerId) {
        if (!settings.isEnabled()) return;
        for (Map<String,Object> event : db.queryForList("SELECT id,provider_id FROM provider_approval_workflow_outbox WHERE provider_id=? AND status IN ('PENDING','FAILED')", providerId)) synchronizeOne(event);
    }

    @Transactional
    protected void synchronizeOne(Map<String,Object> event) {
        long id=((Number)event.get("id")).longValue(), providerId=((Number)event.get("provider_id")).longValue();
        // A crashed API instance can leave a leased event in PROCESSING. Claim it
        // only after the lease expires, so multiple instances never start two cases.
        if (db.update("UPDATE provider_approval_workflow_outbox SET status='PROCESSING',attempts=attempts+1,locked_at=CURRENT_TIMESTAMP WHERE id=? AND (status IN ('PENDING','FAILED') OR (status='PROCESSING' AND locked_at < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 5 MINUTE)))", id)!=1) return;
        try {
            gateway.startApprovalCase(providerId);
            db.update("UPDATE provider_approval_workflow_outbox SET status='SENT',processed_at=CURRENT_TIMESTAMP,locked_at=NULL,last_error=NULL WHERE id=?",id);
            log.info("Provider approval workflow started providerId={}", providerId);
        } catch (Exception error) {
            String message=error.getMessage()==null?error.getClass().getSimpleName():error.getMessage();
            db.update("UPDATE provider_approval_workflow_outbox SET status='FAILED',locked_at=NULL,last_error=? WHERE id=?", message.substring(0,Math.min(1000,message.length())),id);
            log.warn("Provider approval workflow start failed providerId={}: {}",providerId,message);
        }
    }
}
