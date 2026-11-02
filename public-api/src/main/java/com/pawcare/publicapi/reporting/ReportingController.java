package com.pawcare.publicapi.reporting;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.auth.CurrentUser;
import com.pawcare.publicapi.web.ApiException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Read-only reporting APIs. Monetary mutations remain exclusively in WalletService. */
@RestController
@RequestMapping("/api/v1")
public class ReportingController {
    private final JdbcTemplate db;

    public ReportingController(JdbcTemplate db) { this.db = db; }

    @GetMapping("/provider/reports")
    public Map<String, Object> providerReport(@CurrentUser CurrentPrincipal principal,
                                               @RequestParam(required = false) String from,
                                               @RequestParam(required = false) String to) {
        requireRole(principal, "PROVIDER");
        validateRange(from, to);
        Long providerId = scalar("SELECT id FROM providers WHERE owner_profile_id=?", principal.profileId());
        if (providerId == null) throw new ApiException(404, "Provider profile unavailable");
        DateFilter filter = DateFilter.forColumn("b.booking_end", from, to);

        Map<String, Object> summary = one("SELECT "
                + "COALESCE(SUM(b.status='COMPLETED'),0) completed_bookings,"
                + "COALESCE(SUM(CASE WHEN b.status='COMPLETED' THEN b.estimated_price*0.90 ELSE 0 END),0) settled_revenue,"
                + "COALESCE(SUM(CASE WHEN b.status='SERVICE_DONE' THEN b.estimated_price*0.90 ELSE 0 END),0) waiting_customer_confirmation,"
                + "COALESCE(SUM(CASE WHEN b.status='DISPUTED' THEN b.estimated_price*0.90 ELSE 0 END),0) disputed_amount,"
                + "COALESCE(SUM(b.status IN ('PENDING_APPROVAL','CONFIRMED','CHECKED_IN','IN_SERVICE')),0) active_bookings "
                + "FROM bookings b WHERE b.provider_id=?" + filter.sql(), prepend(providerId, filter.args()));
        Map<String, Object> withdrawn = one("SELECT COALESCE(SUM(wr.amount),0) withdrawn_amount "
                + "FROM withdrawal_requests wr JOIN wallets w ON w.id=wr.wallet_id "
                + "WHERE w.owner_type='PROVIDER' AND w.owner_id=? AND wr.status='APPROVED'", providerId);
        Map<String, Object> available = one("SELECT available_balance,locked_balance FROM wallets "
                + "WHERE owner_type='PROVIDER' AND owner_id=?", providerId);
        if (available == null) available = Map.of("available_balance", 0, "locked_balance", 0);

        List<Map<String, Object>> daily = db.queryForList("SELECT DATE_FORMAT(b.booking_end,'%Y-%m-%d') booking_date,"
                + "COUNT(*) completed_bookings,COALESCE(SUM(b.estimated_price*0.90),0) revenue "
                + "FROM bookings b WHERE b.provider_id=? AND b.status='COMPLETED'" + filter.sql()
                + " GROUP BY DATE(b.booking_end) ORDER BY booking_date DESC", prepend(providerId, filter.args()));
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("from", from); result.put("to", to); result.put("summary", summary);
        result.put("wallet", Map.of("availableBalance", available.get("available_balance"), "lockedBalance", available.get("locked_balance")));
        result.put("withdrawnAmount", withdrawn.get("withdrawn_amount")); result.put("daily", daily);
        return result;
    }

    @GetMapping("/admin/reports/finance")
    public Map<String, Object> adminFinanceReport(@CurrentUser CurrentPrincipal principal,
                                                    @RequestParam(required = false) String from,
                                                    @RequestParam(required = false) String to) {
        requireRole(principal, "ADMIN");
        validateRange(from, to);
        DateFilter filter = DateFilter.forColumn("b.created_at", from, to);
        Map<String, Object> summary = one("SELECT "
                + "COALESCE(SUM(b.status IN ('PENDING_APPROVAL','CONFIRMED','CHECKED_IN','IN_SERVICE','SERVICE_DONE','DISPUTED','COMPLETED')),0) funded_bookings,"
                + "COALESCE(SUM(CASE WHEN b.status IN ('PENDING_APPROVAL','CONFIRMED','CHECKED_IN','IN_SERVICE','SERVICE_DONE','DISPUTED','COMPLETED') THEN b.estimated_price ELSE 0 END),0) gmv,"
                + "COALESCE(SUM(CASE WHEN b.status='COMPLETED' THEN b.estimated_price*0.10 ELSE 0 END),0) commission_revenue,"
                + "COALESCE(SUM(b.status='SERVICE_DONE'),0) waiting_customer_confirmation,"
                + "COALESCE(SUM(b.status='DISPUTED'),0) disputed_bookings "
                + "FROM bookings b WHERE 1=1" + filter.sql(), filter.args().toArray());
        Map<String, Object> balances = one("SELECT "
                + "COALESCE(SUM(CASE WHEN owner_type='USER' THEN locked_balance ELSE 0 END),0) escrow_locked,"
                + "COALESCE(SUM(CASE WHEN owner_type='USER' THEN available_balance ELSE 0 END),0) user_available_total,"
                + "COALESCE(SUM(CASE WHEN owner_type='PROVIDER' THEN available_balance ELSE 0 END),0) provider_available_total,"
                + "COALESCE(SUM(CASE WHEN owner_type='PLATFORM_ADMIN' THEN available_balance ELSE 0 END),0) platform_available_total FROM wallets");
        Map<String, Object> withdrawals = one("SELECT COALESCE(SUM(status='PENDING'),0) pending_count,"
                + "COALESCE(SUM(CASE WHEN status='PENDING' THEN amount ELSE 0 END),0) pending_amount,"
                + "COALESCE(SUM(CASE WHEN status='APPROVED' THEN amount ELSE 0 END),0) approved_amount FROM withdrawal_requests");
        List<Map<String, Object>> statuses = db.queryForList("SELECT status,COUNT(*) booking_count,COALESCE(SUM(estimated_price),0) gross_amount "
                + "FROM bookings b WHERE 1=1" + filter.sql() + " GROUP BY status ORDER BY status", filter.args().toArray());
        List<Map<String, Object>> ledger = db.queryForList("SELECT DATE_FORMAT(t.created_at,'%Y-%m-%d %H:%i:%s') created_at,"
                + "t.id,t.booking_id,t.type,t.amount,t.balance_before,t.balance_after,t.description,w.owner_type,w.owner_id "
                + "FROM wallet_transactions t JOIN wallets w ON w.id=t.wallet_id ORDER BY t.created_at DESC,t.id DESC LIMIT 200");
        return Map.of("from", from == null ? "" : from, "to", to == null ? "" : to,
                "summary", summary, "balances", balances, "withdrawals", withdrawals,
                "bookingStatuses", statuses, "ledger", ledger);
    }

    private record DateFilter(String sql, List<Object> args) {
        static DateFilter forColumn(String column, String from, String to) {
            List<Object> args = new ArrayList<>(); StringBuilder where = new StringBuilder();
            if (from != null && !from.isBlank()) { where.append(" AND ").append(column).append(" >= ?"); args.add(from + " 00:00:00"); }
            if (to != null && !to.isBlank()) { where.append(" AND ").append(column).append(" < DATE_ADD(?,INTERVAL 1 DAY)"); args.add(to + " 00:00:00"); }
            return new DateFilter(where.toString(), args);
        }
    }
    private Object[] prepend(Object first, List<Object> rest) { List<Object> args = new ArrayList<>(); args.add(first); args.addAll(rest); return args.toArray(); }
    private void validateRange(String from, String to) { if (from != null && to != null && !from.isBlank() && !to.isBlank() && from.compareTo(to) > 0) throw new ApiException(400, "from must not be after to"); }
    private void requireRole(CurrentPrincipal p, String role) { if (!role.equals(p.role())) throw new ApiException(403, role + " account required"); }
    private Long scalar(String sql, Object... args) { List<Map<String,Object>> rows=db.queryForList(sql,args); return rows.isEmpty()?null:((Number) rows.get(0).get("id")).longValue(); }
    private Map<String,Object> one(String sql,Object... args) { List<Map<String,Object>> rows=db.queryForList(sql,args); return rows.isEmpty()?Map.of():rows.get(0); }
}
