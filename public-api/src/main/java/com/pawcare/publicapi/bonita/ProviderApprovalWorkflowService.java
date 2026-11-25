package com.pawcare.publicapi.bonita;

import com.pawcare.publicapi.audit.AuditService;
import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.bonita.dto.ProviderApprovalCallbackRequest;
import com.pawcare.publicapi.bonita.dto.ProviderApprovalDecisionRequest;
import com.pawcare.publicapi.notification.NotificationService;
import com.pawcare.publicapi.web.ApiException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.List;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Canonical PawCare side of ProviderApproval. Bonita orchestrates the human task,
 * but this service is the sole writer of the provider's approval state.
 */
@Service
public class ProviderApprovalWorkflowService {
    private final JdbcTemplate db;
    private final BonitaProviderApprovalGateway gateway;
    private final ProviderApprovalWorkflowOutbox outbox;
    private final ProviderApprovalWorkflowProperties settings;
    private final NotificationService notifications;
    private final AuditService audit;

    public ProviderApprovalWorkflowService(JdbcTemplate db, BonitaProviderApprovalGateway gateway,
                                           ProviderApprovalWorkflowOutbox outbox,
                                           ProviderApprovalWorkflowProperties settings,
                                           NotificationService notifications, AuditService audit) {
        this.db = db;
        this.gateway = gateway;
        this.outbox = outbox;
        this.settings = settings;
        this.notifications = notifications;
        this.audit = audit;
    }

    public Map<String, Object> submitDecision(CurrentPrincipal principal, long providerId,
                                               ProviderApprovalDecisionRequest request) {
        requireAdmin(principal);
        Map<String, Object> provider = provider(providerId);
        String current = String.valueOf(provider.get("status"));
        if (!"PENDING".equals(current) && !"NEED_MORE_INFO".equals(current)) {
            throw new ApiException(409, "Provider profile is no longer awaiting approval");
        }
        if (provider.get("bonita_case_id") == null) {
            throw new ApiException(409, "Provider approval workflow case is not ready yet; retry shortly");
        }
        String decision = normalizeDecision(request.decision());
        try {
            gateway.submitDecision(providerId, decision, request.reviewNote());
        } catch (ApiException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new ApiException(502, "Unable to submit the approval task to Bonita");
        }
        audit.record(principal.profileId(), "PROVIDER_APPROVAL_TASK_SUBMITTED", "PROVIDER", providerId,
                Map.of("decision", decision, "bonitaCaseId", provider.get("bonita_case_id")));
        return Map.of("success", true, "providerId", providerId, "decision", decision,
                "workflowState", "SUBMITTED_TO_BONITA", "caseId", provider.get("bonita_case_id"));
    }

    @Transactional
    public Map<String, Object> applyBonitaDecision(ProviderApprovalCallbackRequest request) {
        Map<String, Object> provider = provider(request.providerId());
        if (request.caseId() != null && provider.get("bonita_case_id") instanceof Number persistedCase
                && persistedCase.longValue() != request.caseId()) {
            throw new ApiException(409, "Bonita case does not belong to this provider");
        }
        String decision = normalizeDecision(request.decision());
        String current = String.valueOf(provider.get("status"));
        if (decision.equals(current)) {
            return Map.of("success", true, "providerId", request.providerId(), "decision", decision, "idempotent", true);
        }
        if (!"PENDING".equals(current) && !"NEED_MORE_INFO".equals(current)) {
            throw new ApiException(409, "Provider profile has already been decided");
        }
        String note = blankToNull(request.reviewNote());
        int changed;
        if ("APPROVED".equals(decision)) {
            changed = db.update("UPDATE providers SET status='APPROVED',is_active=1,rejection_reason=NULL,approval_review_note=?,approval_decided_at=CURRENT_TIMESTAMP WHERE id=? AND status IN ('PENDING','NEED_MORE_INFO')",
                    note, request.providerId());
        } else {
            changed = db.update("UPDATE providers SET status='REJECTED',is_active=0,rejection_reason=?,approval_review_note=?,approval_decided_at=CURRENT_TIMESTAMP WHERE id=? AND status IN ('PENDING','NEED_MORE_INFO')",
                    note == null ? "Provider registration was not approved" : note, note, request.providerId());
        }
        if (changed != 1) {
            // A concurrent callback has completed the state transition; avoid duplicate notification/ledger-like effects.
            return Map.of("success", true, "providerId", request.providerId(), "decision", decision, "idempotent", true);
        }
        long ownerProfileId = ((Number) provider.get("owner_profile_id")).longValue();
        boolean approved = "APPROVED".equals(decision);
        notifications.notifyOnce(ownerProfileId,
                approved ? "Hồ sơ Provider đã được duyệt" : "Hồ sơ Provider chưa được duyệt",
                approved ? "Tài khoản Provider của bạn đã sẵn sàng hoạt động." : "Vui lòng xem ghi chú của quản trị viên và cập nhật hồ sơ.",
                "PROVIDER_APPROVAL", "PROVIDER", request.providerId(),
                "provider-approval-" + request.providerId() + "-" + decision);
        // Map.of rejects null values. caseId is intentionally optional because a
        // Bonita REST connector only needs the providerId/decision variables.
        Map<String, Object> auditDetails = new LinkedHashMap<>();
        auditDetails.put("decision", decision);
        if (request.caseId() != null) auditDetails.put("bonitaCaseId", request.caseId());
        audit.record(null, approved ? "PROVIDER_APPROVED_BY_WORKFLOW" : "PROVIDER_REJECTED_BY_WORKFLOW",
                "PROVIDER", request.providerId(), auditDetails);
        return Map.of("success", true, "providerId", request.providerId(), "decision", decision, "idempotent", false);
    }

    public Map<String, Object> status(CurrentPrincipal principal, long providerId) {
        requireAdmin(principal);
        Map<String, Object> provider = provider(providerId);
        List<Map<String, Object>> events = db.queryForList(
                "SELECT id,event_type,status,attempts,last_error,processed_at,created_at FROM provider_approval_workflow_outbox WHERE provider_id=? ORDER BY id",
                providerId);
        return Map.of("provider", provider, "events", events);
    }

    public Map<String, Object> retry(CurrentPrincipal principal, long providerId) {
        requireAdmin(principal);
        provider(providerId);
        int reset = db.update("UPDATE provider_approval_workflow_outbox SET status='PENDING',last_error=NULL,locked_at=NULL WHERE provider_id=? AND status='FAILED'", providerId);
        outbox.synchronizeNow(providerId);
        return Map.of("success", true, "providerId", providerId, "eventsReset", reset);
    }

    public void requireBridgeToken(String workflowToken, String authorization) {
        String expected = settings.getBridgeToken();
        if (expected == null || expected.isBlank()) throw new ApiException(503, "ProviderApproval bridge token is not configured");
        String supplied = cleanToken(workflowToken == null || workflowToken.isBlank() ? authorization : workflowToken);
        if (supplied == null || !MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), supplied.getBytes(StandardCharsets.UTF_8))) {
            throw new ApiException(401, "Invalid workflow bridge token");
        }
    }

    private Map<String, Object> provider(long providerId) {
        List<Map<String, Object>> rows = db.queryForList(
                "SELECT id,owner_profile_id,status,is_active,bonita_case_id,bonita_process_definition_id,approval_review_note,approval_decided_at FROM providers WHERE id=?", providerId);
        if (rows.isEmpty()) throw new ApiException(404, "Provider not found");
        return rows.get(0);
    }

    private String normalizeDecision(String decision) { return decision.trim().toUpperCase(Locale.ROOT); }
    private String blankToNull(String value) { return value == null || value.isBlank() ? null : value.trim(); }
    private String cleanToken(String token) {
        if (token == null) return null;
        String trimmed = token.trim();
        return trimmed.replaceFirst("(?i)^(apikey|bearer)\\s+", "").trim();
    }
    private void requireAdmin(CurrentPrincipal principal) {
        if (!"ADMIN".equals(principal.role())) throw new ApiException(403, "ADMIN account required");
    }
}
