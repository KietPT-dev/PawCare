package com.pawcare.publicapi.wallet;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.auth.CurrentUser;
import com.pawcare.publicapi.web.ApiException;
import java.math.BigDecimal;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/provider-withdrawals")
public class AdminProviderWithdrawalController {
    private final JdbcTemplate db;
    public AdminProviderWithdrawalController(JdbcTemplate db) { this.db = db; }

    @GetMapping public List<Map<String,Object>> list(@CurrentUser CurrentPrincipal user) { admin(user); return db.queryForList("SELECT r.*,p.name provider_name FROM provider_withdrawal_requests r JOIN provider_wallets w ON w.id=r.wallet_id JOIN providers p ON p.id=w.provider_id ORDER BY r.created_at DESC"); }

    @PutMapping("/{id}") public Map<String,Object> decide(@CurrentUser CurrentPrincipal user,@PathVariable long id,@RequestBody Map<String,Object> body) {
        admin(user); String status=String.valueOf(body.get("status")).toUpperCase(Locale.ROOT); if(!List.of("APPROVED","REJECTED").contains(status))throw new ApiException(400,"status must be APPROVED or REJECTED");
        Map<String,Object> request=one("SELECT * FROM provider_withdrawal_requests WHERE id=?",id);if(request==null)throw new ApiException(404,"Withdrawal request not found");if(!"PENDING".equals(request.get("status")))throw new ApiException(409,"Withdrawal request has already been decided");
        if("REJECTED".equals(status))db.update("UPDATE provider_wallets SET available_balance=available_balance+? WHERE id=?",request.get("amount"),request.get("wallet_id"));
        db.update("UPDATE provider_withdrawal_requests SET status=?,admin_note=?,reviewed_at=CURRENT_TIMESTAMP WHERE id=?",status,body.get("adminNote"),id);
        return Map.of("success",true,"id",id,"status",status);
    }
    private void admin(CurrentPrincipal user){if(!"ADMIN".equals(user.role()))throw new ApiException(403,"Admin account required");}
    private Map<String,Object> one(String sql,Object... args){List<Map<String,Object>> rows=db.queryForList(sql,args);return rows.isEmpty()?null:rows.get(0);}
}
