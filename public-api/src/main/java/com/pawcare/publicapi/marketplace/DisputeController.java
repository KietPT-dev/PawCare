package com.pawcare.publicapi.marketplace;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.auth.CurrentUser;
import com.pawcare.publicapi.marketplace.dto.DisputeResolutionRequest;
import com.pawcare.publicapi.web.ApiException;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

/** Back-office decision endpoint; the Bonita Finance page can call this API. */
@RestController
@RequestMapping("/api/v1/admin/disputes")
public class DisputeController {
    private final BookingWorkflowService workflow;
    private final JdbcTemplate db;

    public DisputeController(BookingWorkflowService workflow, JdbcTemplate db) {
        this.workflow = workflow;
        this.db = db;
    }

    @GetMapping
    public List<Map<String, Object>> list(@CurrentUser CurrentPrincipal principal,
                                           @RequestParam(required = false) String status) {
        if (!"ADMIN".equals(principal.role())) throw new ApiException(403, "Admin account required");
        String normalized = status == null || status.isBlank() ? null : status.trim().toUpperCase();
        String sql = "SELECT c.id complaint_id,c.status complaint_status,c.content,c.admin_response,"
                + "DATE_FORMAT(c.created_at,'%Y-%m-%d %H:%i:%s') created_at,"
                + "b.id booking_id,b.status booking_status,b.estimated_price,"
                + "u.full_name customer_name,p.name provider_name "
                + "FROM complaints c JOIN bookings b ON b.id=c.booking_id "
                + "JOIN user_profiles u ON u.id=c.customer_profile_id JOIN providers p ON p.id=c.provider_id ";
        if (normalized == null) return db.queryForList(sql + "WHERE b.status='DISPUTED' OR c.status IN ('OPEN','IN_PROGRESS') ORDER BY c.created_at DESC");
        return db.queryForList(sql + "WHERE c.status=? ORDER BY c.created_at DESC", normalized);
    }

    @PutMapping("/{bookingId}")
    public Map<String, Object> resolve(@CurrentUser CurrentPrincipal principal, @PathVariable long bookingId,
                                       @RequestBody DisputeResolutionRequest request) {
        return workflow.resolveDispute(principal, bookingId, request.action(), request.adminNote());
    }
}
