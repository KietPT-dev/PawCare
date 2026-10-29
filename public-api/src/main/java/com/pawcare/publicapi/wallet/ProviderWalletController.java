package com.pawcare.publicapi.wallet;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.auth.CurrentUser;
import com.pawcare.publicapi.web.ApiException;
import java.math.BigDecimal;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/provider/wallet")
public class ProviderWalletController {
    private final JdbcTemplate db;
    public ProviderWalletController(JdbcTemplate db) { this.db = db; }

    @GetMapping
    public Map<String,Object> wallet(@CurrentUser CurrentPrincipal user) {
        long providerId=providerId(user); Map<String,Object> wallet=wallet(providerId);
        Map<String,Object> result=new LinkedHashMap<>(); result.put("availableBalance",wallet.get("available_balance")); result.put("totalEarned",wallet.get("total_earned"));
        result.put("pendingRevenue",one("SELECT COALESCE(SUM(estimated_price*0.9),0) amount FROM bookings WHERE provider_id=? AND status IN ('PENDING','CONFIRMED','CHECKED_IN','IN_SERVICE')",providerId).get("amount"));
        return result;
    }

    @GetMapping("/transactions")
    public List<Map<String,Object>> transactions(@CurrentUser CurrentPrincipal user) {
        Map<String,Object> wallet=wallet(providerId(user));
        return db.queryForList("SELECT t.*,b.booking_start,u.full_name customer_name,s.name service_name FROM provider_wallet_transactions t JOIN bookings b ON b.id=t.booking_id JOIN user_profiles u ON u.id=b.customer_profile_id JOIN services s ON s.id=b.service_id WHERE t.wallet_id=? AND t.type='BOOKING_PAYOUT' ORDER BY t.created_at DESC",wallet.get("id"));
    }

    @GetMapping("/withdrawals")
    public List<Map<String,Object>> withdrawals(@CurrentUser CurrentPrincipal user) {
        return db.queryForList("SELECT w.* FROM provider_withdrawal_requests w WHERE w.wallet_id=? ORDER BY w.created_at DESC",wallet(providerId(user)).get("id"));
    }

    @PostMapping("/withdrawals")
    public Map<String,Object> withdraw(@CurrentUser CurrentPrincipal user,@RequestBody Map<String,Object> body) {
        Map<String,Object> wallet=wallet(providerId(user)); BigDecimal amount=amount(body,"amount");
        String bank=required(body,"bankName"), number=required(body,"bankAccountNo"), owner=required(body,"bankAccountName");
        BigDecimal available=(BigDecimal)wallet.get("available_balance"); if(available.compareTo(amount)<0) throw new ApiException(409,"Số dư khả dụng không đủ để rút tiền");
        db.update("UPDATE provider_wallets SET available_balance=available_balance-? WHERE id=?",amount,wallet.get("id"));
        db.update("INSERT INTO provider_withdrawal_requests(wallet_id,amount,bank_name,bank_account_no,bank_account_name) VALUES(?,?,?,?,?)",wallet.get("id"),amount,bank,number,owner);
        return Map.of("success",true,"id",db.queryForObject("SELECT LAST_INSERT_ID()",Long.class),"status","PENDING");
    }

    private Map<String,Object> wallet(long providerId) { db.update("INSERT IGNORE INTO provider_wallets(provider_id) VALUES(?)",providerId);return one("SELECT * FROM provider_wallets WHERE provider_id=?",providerId); }
    private long providerId(CurrentPrincipal user) { if(!"PROVIDER".equals(user.role()))throw new ApiException(403,"Provider account required");Map<String,Object> row=one("SELECT id FROM providers WHERE owner_profile_id=? AND is_active=1",user.profileId());if(row==null)throw new ApiException(403,"Provider profile unavailable");return ((Number)row.get("id")).longValue(); }
    private Map<String,Object> one(String sql,Object... values) { List<Map<String,Object>> rows=db.queryForList(sql,values);return rows.isEmpty()?null:rows.get(0); }
    private String required(Map<String,Object> b,String key) { Object value=b.get(key);if(value==null||value.toString().trim().isEmpty())throw new ApiException(400,key+" is required");return value.toString().trim(); }
    private BigDecimal amount(Map<String,Object> b,String key) { try { BigDecimal result=new BigDecimal(required(b,key));if(result.signum()<=0)throw new ApiException(400,"amount must be positive");return result; } catch(NumberFormatException e) { throw new ApiException(400,"amount must be a number"); } }
}
