package com.pawcare.publicapi.reporting;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.auth.CurrentUser;
import com.pawcare.publicapi.web.ApiException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.time.ZoneId;
import java.time.DateTimeException;
import java.nio.charset.StandardCharsets;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
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
                                               @RequestParam(required = false) String to,
                                               @RequestParam(defaultValue = "Asia/Ho_Chi_Minh") String timezone,
                                               @RequestParam(defaultValue = "DAY") String granularity,
                                               @RequestParam(defaultValue = "0") int page,
                                               @RequestParam(defaultValue = "50") int size) {
        requireRole(principal, "PROVIDER");
        validateRange(from, to);
        ReportQuery query = reportQuery(timezone, granularity, page, size);
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
                + "WHERE w.owner_type='PROVIDER' AND w.owner_id=? AND wr.status='PAID'", providerId);
        Map<String, Object> available = one("SELECT available_balance,locked_balance FROM wallets "
                + "WHERE owner_type='PROVIDER' AND owner_id=?", providerId);
        if (available == null) available = Map.of("available_balance", 0, "locked_balance", 0);

        String providerPeriod = query.periodSql("b.booking_end");
        List<Map<String, Object>> daily = db.queryForList("SELECT " + providerPeriod + " period," + providerPeriod + " booking_date,"
                + "COUNT(*) completed_bookings,COALESCE(SUM(b.estimated_price*0.90),0) revenue "
                + "FROM bookings b WHERE b.provider_id=? AND b.status='COMPLETED'" + filter.sql()
                + " GROUP BY period ORDER BY period DESC", prepend(providerId, filter.args()));
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("from", from); result.put("to", to); result.put("summary", summary);
        result.put("timezone", query.timezone()); result.put("granularity", query.granularity());
        result.put("wallet", Map.of("availableBalance", available.get("available_balance"), "lockedBalance", available.get("locked_balance")));
        result.put("withdrawnAmount", withdrawn.get("withdrawn_amount")); result.put("daily", daily);
        result.put("series", daily); result.put("page", query.page()); result.put("size", query.size());
        return result;
    }

    @GetMapping("/admin/reports/finance")
    public Map<String, Object> adminFinanceReport(@CurrentUser CurrentPrincipal principal,
                                                    @RequestParam(required = false) String from,
                                                    @RequestParam(required = false) String to,
                                                    @RequestParam(defaultValue = "Asia/Ho_Chi_Minh") String timezone,
                                                    @RequestParam(defaultValue = "DAY") String granularity,
                                                    @RequestParam(defaultValue = "0") int page,
                                                    @RequestParam(defaultValue = "50") int size) {
        requireRole(principal, "ADMIN");
        validateRange(from, to);
        ReportQuery query = reportQuery(timezone, granularity, page, size);
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
                + "COALESCE(SUM(CASE WHEN status='APPROVED' THEN amount ELSE 0 END),0) approved_amount,"
                + "COALESCE(SUM(CASE WHEN status='PROCESSING' THEN amount ELSE 0 END),0) processing_amount,"
                + "COALESCE(SUM(CASE WHEN status='PAID' THEN amount ELSE 0 END),0) paid_amount FROM withdrawal_requests");
        List<Map<String, Object>> statuses = db.queryForList("SELECT status,COUNT(*) booking_count,COALESCE(SUM(estimated_price),0) gross_amount "
                + "FROM bookings b WHERE 1=1" + filter.sql() + " GROUP BY status ORDER BY status", filter.args().toArray());
        List<Map<String, Object>> series = db.queryForList("SELECT " + query.periodSql("b.created_at") + " period,"
                + "COALESCE(SUM(CASE WHEN b.status='COMPLETED' THEN b.estimated_price ELSE 0 END),0) completed_gmv,"
                + "COALESCE(SUM(CASE WHEN b.status='COMPLETED' THEN b.estimated_price*0.10 ELSE 0 END),0) commission "
                + "FROM bookings b WHERE 1=1" + filter.sql() + " GROUP BY period ORDER BY period ASC", filter.args().toArray());
        List<Map<String, Object>> ledger = db.queryForList("SELECT DATE_FORMAT(t.created_at,'%Y-%m-%d %H:%i:%s') created_at,"
                + "t.id,t.booking_id,t.type,t.amount,t.balance_before,t.balance_after,t.description,w.owner_type,w.owner_id "
                + "FROM wallet_transactions t JOIN wallets w ON w.id=t.wallet_id ORDER BY t.created_at DESC,t.id DESC LIMIT ? OFFSET ?", query.size(), query.page() * query.size());
        Long ledgerTotal = scalarValue("SELECT COUNT(*) AS total FROM wallet_transactions");
        return Map.of("from", from == null ? "" : from, "to", to == null ? "" : to, "timezone", query.timezone(), "granularity", query.granularity(),
                "summary", summary, "balances", balances, "withdrawals", withdrawals,
                "bookingStatuses", statuses, "series", series, "ledger", ledger, "page", query.page(), "size", query.size(), "total", ledgerTotal);
    }

    @GetMapping(value = "/admin/reports/finance.csv", produces = "text/csv")
    public ResponseEntity<byte[]> adminFinanceCsv(@CurrentUser CurrentPrincipal principal,
                                                    @RequestParam(required = false) String from,
                                                    @RequestParam(required = false) String to,
                                                    @RequestParam(defaultValue = "Asia/Ho_Chi_Minh") String timezone) {
        requireRole(principal, "ADMIN");
        validateRange(from, to); reportQuery(timezone, "DAY", 0, 1);
        DateFilter filter = DateFilter.forColumn("b.created_at", from, to);
        List<Map<String, Object>> rows = db.queryForList("SELECT DATE_FORMAT(b.created_at,'%Y-%m-%d') date,b.status,COUNT(*) bookings,"
                + "COALESCE(SUM(b.estimated_price),0) gross_amount FROM bookings b WHERE 1=1" + filter.sql()
                + " GROUP BY date,b.status ORDER BY date,status", filter.args().toArray());
        StringBuilder csv = new StringBuilder("date,status,bookings,gross_amount\\n");
        for (Map<String,Object> row : rows) csv.append(row.get("date")).append(',').append(row.get("status")).append(',')
                .append(row.get("bookings")).append(',').append(row.get("gross_amount")).append('\\n');
        return ResponseEntity.ok().header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename("pawcare-finance.csv").build().toString())
                .contentType(new MediaType("text", "csv", StandardCharsets.UTF_8)).body(csv.toString().getBytes(StandardCharsets.UTF_8));
    }

    private record DateFilter(String sql, List<Object> args) {
        static DateFilter forColumn(String column, String from, String to) {
            List<Object> args = new ArrayList<>(); StringBuilder where = new StringBuilder();
            if (from != null && !from.isBlank()) { where.append(" AND ").append(column).append(" >= ?"); args.add(from + " 00:00:00"); }
            if (to != null && !to.isBlank()) { where.append(" AND ").append(column).append(" < DATE_ADD(?,INTERVAL 1 DAY)"); args.add(to + " 00:00:00"); }
            return new DateFilter(where.toString(), args);
        }
    }
    private record ReportQuery(String timezone, String granularity, int page, int size) {
        String periodSql(String column) { return switch (granularity) {
            case "WEEK" -> "DATE_FORMAT(" + column + ",'%x-W%v')";
            case "MONTH" -> "DATE_FORMAT(" + column + ",'%Y-%m')";
            default -> "DATE_FORMAT(" + column + ",'%Y-%m-%d')";
        }; }
    }
    private ReportQuery reportQuery(String timezone, String granularity, int page, int size) {
        try { ZoneId.of(timezone); } catch (DateTimeException e) { throw new ApiException(400, "Unsupported timezone"); }
        String normalized = granularity == null ? "DAY" : granularity.toUpperCase(java.util.Locale.ROOT);
        if (!List.of("DAY", "WEEK", "MONTH").contains(normalized)) throw new ApiException(400, "granularity must be DAY, WEEK or MONTH");
        if (page < 0 || size < 1 || size > 200) throw new ApiException(400, "page must be >= 0 and size must be 1..200");
        return new ReportQuery(timezone, normalized, page, size);
    }
    private Object[] prepend(Object first, List<Object> rest) { List<Object> args = new ArrayList<>(); args.add(first); args.addAll(rest); return args.toArray(); }
    private void validateRange(String from, String to) { if (from != null && to != null && !from.isBlank() && !to.isBlank() && from.compareTo(to) > 0) throw new ApiException(400, "from must not be after to"); }
    private void requireRole(CurrentPrincipal p, String role) { if (!role.equals(p.role())) throw new ApiException(403, role + " account required"); }
    private Long scalar(String sql, Object... args) { List<Map<String,Object>> rows=db.queryForList(sql,args); return rows.isEmpty()?null:((Number) rows.get(0).get("id")).longValue(); }
    private Long scalarValue(String sql, Object... args) { List<Map<String,Object>> rows=db.queryForList(sql,args); return rows.isEmpty()?0L:((Number) rows.get(0).values().iterator().next()).longValue(); }
    private Map<String,Object> one(String sql,Object... args) { List<Map<String,Object>> rows=db.queryForList(sql,args); return rows.isEmpty()?Map.of():rows.get(0); }
}
