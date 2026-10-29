package com.pawcare.publicapi.wallet;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.wallet.dto.WithdrawRequest;
import com.pawcare.publicapi.wallet.dto.WithdrawalDecisionRequest;
import com.pawcare.publicapi.web.ApiException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * The only component allowed to mutate wallet balances. Every mutation locks
 * the wallet row and writes an immutable wallet_transactions row in the same
 * database transaction.
 */
@Service
public class WalletService {
    private static final Logger log = LoggerFactory.getLogger(WalletService.class);
    private static final String USER = "USER";
    private static final String PROVIDER = "PROVIDER";
    private static final String PLATFORM = "PLATFORM_ADMIN";
    private static final Pattern PAYMENT_CODE = Pattern.compile("\\bPAW(\\d+)\\b", Pattern.CASE_INSENSITIVE);

    private final JdbcTemplate db;
    private final String webhookToken;
    private final String qrBank;
    private final String qrAccount;
    private final String qrAccountName;

    public WalletService(JdbcTemplate db,
            @Value("${pawcare.wallet.webhook-token:}") String webhookToken,
            @Value("${pawcare.wallet.vietqr.bank-code:}") String qrBank,
            @Value("${pawcare.wallet.vietqr.account-no:}") String qrAccount,
            @Value("${pawcare.wallet.vietqr.account-name:PawCare}") String qrAccountName) {
        this.db = db;
        this.webhookToken = webhookToken;
        this.qrBank = qrBank;
        this.qrAccount = qrAccount;
        this.qrAccountName = qrAccountName;
    }

    /** Called inside booking creation's transaction. */
    public Map<String, Object> fundBooking(long customerId, long bookingId, BigDecimal amount, PaymentMethod method) {
        amount = money(amount);
        if (amount.signum() <= 0) throw new ApiException(400, "Booking amount must be positive");
        return method == PaymentMethod.WALLET
                ? holdFromWallet(customerId, bookingId, amount)
                : createVietQrDeposit(customerId, bookingId, amount);
    }

    @Transactional
    public Map<String, Object> holdFromWallet(long customerId, long bookingId, BigDecimal amount) {
        Map<String, Object> wallet = lockWallet(USER, customerId);
        BigDecimal available = money((BigDecimal) wallet.get("available_balance"));
        if (available.compareTo(amount) < 0) {
            throw new ApiException(409, "Insufficient PawCare wallet balance");
        }
        BigDecimal after = available.subtract(amount);
        db.update("UPDATE wallets SET available_balance=?, locked_balance=locked_balance+? WHERE id=?",
                after, amount, wallet.get("id"));
        transaction(wallet, bookingId, "ESCROW_HOLD", amount.negate(), available, after,
                "Escrow hold: available balance moved to locked balance for booking #" + bookingId);
        markBookingAwaitingApproval(bookingId, customerId, "Paid from PawCare wallet; escrow held");
        return Map.of("paymentMethod", "WALLET", "status", "ESCROW_HELD", "bookingId", bookingId,
                "availableBalance", after, "lockedBalance", money((BigDecimal) wallet.get("locked_balance")).add(amount));
    }

    @Transactional
    public Map<String, Object> createVietQrDeposit(long customerId, long bookingId, BigDecimal amount) {
        Map<String, Object> existing = one("SELECT * FROM payment_deposits WHERE booking_id=? FOR UPDATE", bookingId);
        if (existing != null) {
            return depositResponse(existing);
        }
        db.update("INSERT INTO payment_deposits(user_id,booking_id,payment_code,amount,status) VALUES(?,?,?,?,'CREATED')",
                customerId, bookingId, "TMP-" + UUID.randomUUID(), amount);
        long id = lastId();
        String code = "PAW" + id;
        String url = qrUrl(code, amount);
        db.update("UPDATE payment_deposits SET payment_code=?,qr_url=? WHERE id=?", code, url, id);
        return Map.of("paymentMethod", "VIETQR", "status", "PENDING_PAYMENT", "bookingId", bookingId,
                "paymentDepositId", id, "paymentCode", code, "amount", amount, "qrUrl", url);
    }

    /**
     * Handles SePay/PayOS-style payloads after a signature/token validating
     * relay. It is idempotent on bank_tran_id and performs deposit + hold as
     * one ACID transaction.
     */
    @Transactional
    public Map<String, Object> processBankWebhook(String suppliedToken, Map<String, Object> raw) {
        verifyWebhookToken(suppliedToken);
        Map<String, Object> payload = unwrap(raw);
        String bankTransactionId = first(payload, "bank_tran_id", "bankTranId", "transaction_id", "transactionId", "id", "referenceCode");
        String content = first(payload, "payment_code", "paymentCode", "content", "description", "transferContent", "orderCode");
        BigDecimal received = decimal(first(payload, "amount", "transferAmount", "amountReceived", "transfer_amount"));
        if (blank(bankTransactionId) || blank(content) || received == null || received.signum() <= 0) {
            throw new ApiException(400, "Webhook requires bank transaction id, transfer content/payment code and positive amount");
        }
        Matcher matcher = PAYMENT_CODE.matcher(content.toUpperCase(Locale.ROOT));
        if (!matcher.find()) throw new ApiException(400, "Payment code PAW{id} was not found in transfer content");
        String paymentCode = "PAW" + matcher.group(1);

        Map<String, Object> duplicate = one("SELECT id,booking_id,status FROM payment_deposits WHERE bank_tran_id=? FOR UPDATE", bankTransactionId);
        if (duplicate != null) return Map.of("success", true, "idempotent", true, "depositId", duplicate.get("id"), "status", duplicate.get("status"));

        Map<String, Object> deposit = one("SELECT * FROM payment_deposits WHERE payment_code=? FOR UPDATE", paymentCode);
        if (deposit == null) throw new ApiException(404, "Payment code not found");
        if ("ESCROW_HELD".equals(deposit.get("status"))) return Map.of("success", true, "idempotent", true, "depositId", deposit.get("id"), "status", "ESCROW_HELD");
        BigDecimal expected = money((BigDecimal) deposit.get("amount"));
        if (money(received).compareTo(expected) != 0) throw new ApiException(409, "Transferred amount does not match payment deposit");

        long userId = ((Number) deposit.get("user_id")).longValue();
        long bookingId = ((Number) deposit.get("booking_id")).longValue();
        Map<String, Object> booking = one("SELECT * FROM bookings WHERE id=? FOR UPDATE", bookingId);
        if (booking == null || !"PENDING_PAYMENT".equals(booking.get("status"))) {
            throw new ApiException(409, "Booking is no longer waiting for this payment");
        }
        Map<String, Object> wallet = lockWallet(USER, userId);
        BigDecimal beforeDeposit = money((BigDecimal) wallet.get("available_balance"));
        BigDecimal credited = beforeDeposit.add(expected);
        db.update("UPDATE wallets SET available_balance=? WHERE id=?", credited, wallet.get("id"));
        transaction(wallet, bookingId, "DEPOSIT", expected, beforeDeposit, credited,
                "VietQR bank deposit " + bankTransactionId + " for " + paymentCode);

        BigDecimal afterHold = credited.subtract(expected);
        db.update("UPDATE wallets SET available_balance=?, locked_balance=locked_balance+? WHERE id=?",
                afterHold, expected, wallet.get("id"));
        transaction(wallet, bookingId, "ESCROW_HOLD", expected.negate(), credited, afterHold,
                "Escrow hold after VietQR deposit for booking #" + bookingId);
        db.update("UPDATE payment_deposits SET bank_tran_id=?,status='ESCROW_HELD' WHERE id=?", bankTransactionId, deposit.get("id"));
        markBookingAwaitingApproval(bookingId, userId, "VietQR received; escrow held");
        return Map.of("success", true, "idempotent", false, "depositId", deposit.get("id"),
                "bookingId", bookingId, "status", "ESCROW_HELD");
    }

    /** Releases a funded booking exactly once. Safe to call for rejected/cancelled bookings. */
    @Transactional
    public void releaseEscrowForBooking(long bookingId, String reason) {
        Map<String, Object> booking = one("SELECT * FROM bookings WHERE id=? FOR UPDATE", bookingId);
        if (booking == null) throw new ApiException(404, "Booking not found");
        Map<String, Object> hold = one("SELECT id FROM wallet_transactions WHERE booking_id=? AND type='ESCROW_HOLD' FOR UPDATE", bookingId);
        if (hold == null || one("SELECT id FROM wallet_transactions WHERE booking_id=? AND type='ESCROW_RELEASE' AND description LIKE 'Escrow released%'", bookingId) != null) return;

        long customerId = ((Number) booking.get("customer_profile_id")).longValue();
        BigDecimal amount = money((BigDecimal) booking.get("estimated_price"));
        Map<String, Object> wallet = lockWallet(USER, customerId);
        BigDecimal locked = money((BigDecimal) wallet.get("locked_balance"));
        if (locked.compareTo(amount) < 0) throw new IllegalStateException("Escrow ledger is inconsistent for booking " + bookingId);
        BigDecimal available = money((BigDecimal) wallet.get("available_balance"));
        BigDecimal after = available.add(amount);
        db.update("UPDATE wallets SET available_balance=?,locked_balance=? WHERE id=?", after, locked.subtract(amount), wallet.get("id"));
        transaction(wallet, bookingId, "ESCROW_RELEASE", amount, available, after, "Escrow released: " + reason);
        db.update("UPDATE payment_deposits SET status='EXPIRED' WHERE booking_id=? AND status='ESCROW_HELD'", bookingId);
    }

    /** Transfers one held amount to provider and platform only after completion. */
    @Transactional
    public void settleCompletedBooking(long bookingId) {
        Map<String, Object> booking = one("SELECT * FROM bookings WHERE id=? FOR UPDATE", bookingId);
        if (booking == null || !"COMPLETED".equals(booking.get("status"))) throw new ApiException(409, "Only completed bookings can be settled");
        if (one("SELECT id FROM wallet_transactions WHERE booking_id=? AND type='PROVIDER_PAYOUT'", bookingId) != null) return;
        if (one("SELECT id FROM wallet_transactions WHERE booking_id=? AND type='ESCROW_HOLD'", bookingId) == null) return; // legacy/unpaid booking

        BigDecimal amount = money((BigDecimal) booking.get("estimated_price"));
        BigDecimal fee = amount.multiply(new BigDecimal("0.10")).setScale(2, RoundingMode.HALF_UP);
        BigDecimal payout = amount.subtract(fee);
        Map<String, Object> customer = lockWallet(USER, ((Number) booking.get("customer_profile_id")).longValue());
        Map<String, Object> provider = lockWallet(PROVIDER, ((Number) booking.get("provider_id")).longValue());
        Map<String, Object> platform = lockWallet(PLATFORM, 0L);
        BigDecimal customerLocked = money((BigDecimal) customer.get("locked_balance"));
        if (customerLocked.compareTo(amount) < 0) throw new IllegalStateException("Escrow ledger is inconsistent for booking " + bookingId);
        db.update("UPDATE wallets SET locked_balance=? WHERE id=?", customerLocked.subtract(amount), customer.get("id"));
        transaction(customer, bookingId, "ESCROW_RELEASE", amount.negate(), customerLocked, customerLocked.subtract(amount),
                "Escrow consumed for completed booking #" + bookingId);

        BigDecimal providerBefore = money((BigDecimal) provider.get("available_balance"));
        db.update("UPDATE wallets SET available_balance=? WHERE id=?", providerBefore.add(payout), provider.get("id"));
        transaction(provider, bookingId, "PROVIDER_PAYOUT", payout, providerBefore, providerBefore.add(payout),
                "Provider payout (90%) for booking #" + bookingId);

        BigDecimal platformBefore = money((BigDecimal) platform.get("available_balance"));
        db.update("UPDATE wallets SET available_balance=? WHERE id=?", platformBefore.add(fee), platform.get("id"));
        transaction(platform, bookingId, "COMMISSION_FEE", fee, platformBefore, platformBefore.add(fee),
                "Platform commission (10%) for booking #" + bookingId);
    }

    public Map<String, Object> myWallet(CurrentPrincipal principal) {
        Map<String, Object> wallet = ensureWallet(ownerType(principal), ownerId(principal));
        return walletView(wallet);
    }

    public List<Map<String, Object>> myTransactions(CurrentPrincipal principal) {
        Map<String, Object> wallet = ensureWallet(ownerType(principal), ownerId(principal));
        return db.queryForList("SELECT * FROM wallet_transactions WHERE wallet_id=? ORDER BY created_at DESC,id DESC", wallet.get("id"));
    }

    @Transactional
    public Map<String, Object> requestWithdrawal(CurrentPrincipal principal, WithdrawRequest request) {
        validateWithdraw(request);
        Map<String, Object> wallet = lockWallet(ownerType(principal), ownerId(principal));
        BigDecimal amount = money(request.amount());
        BigDecimal available = money((BigDecimal) wallet.get("available_balance"));
        if (available.compareTo(amount) < 0) throw new ApiException(409, "Insufficient available wallet balance");
        BigDecimal after = available.subtract(amount);
        db.update("UPDATE wallets SET available_balance=?,locked_balance=locked_balance+? WHERE id=?", after, amount, wallet.get("id"));
        transaction(wallet, null, "WITHDRAWAL", amount.negate(), available, after, "Withdrawal request reserved in locked balance");
        db.update("INSERT INTO withdrawal_requests(wallet_id,amount,bank_name,bank_account_no,bank_account_name,bonita_case_id,status) VALUES(?,?,?,?,?,?, 'PENDING')",
                wallet.get("id"), amount, clean(request.bankName()), clean(request.bankAccountNo()), clean(request.bankAccountName()), request.bonitaCaseId());
        return Map.of("success", true, "id", lastId(), "status", "PENDING", "amount", amount);
    }

    public List<Map<String, Object>> listWithdrawals(CurrentPrincipal principal, String status) {
        requireAdmin(principal);
        if (blank(status)) return db.queryForList("SELECT wr.*,w.owner_type,w.owner_id FROM withdrawal_requests wr JOIN wallets w ON w.id=wr.wallet_id ORDER BY wr.created_at DESC");
        return db.queryForList("SELECT wr.*,w.owner_type,w.owner_id FROM withdrawal_requests wr JOIN wallets w ON w.id=wr.wallet_id WHERE wr.status=? ORDER BY wr.created_at DESC", status.toUpperCase(Locale.ROOT));
    }

    @Transactional
    public Map<String, Object> decideWithdrawal(CurrentPrincipal principal, long id, WithdrawalDecisionRequest request) {
        requireAdmin(principal);
        String decision = clean(request.status()).toUpperCase(Locale.ROOT);
        if (!List.of("APPROVED", "REJECTED").contains(decision)) throw new ApiException(400, "status must be APPROVED or REJECTED");
        Map<String, Object> withdrawal = one("SELECT * FROM withdrawal_requests WHERE id=? FOR UPDATE", id);
        if (withdrawal == null) throw new ApiException(404, "Withdrawal request not found");
        if (!"PENDING".equals(withdrawal.get("status"))) throw new ApiException(409, "Withdrawal request has already been decided");
        Map<String, Object> wallet = lockWalletById(((Number) withdrawal.get("wallet_id")).longValue());
        BigDecimal amount = money((BigDecimal) withdrawal.get("amount"));
        BigDecimal locked = money((BigDecimal) wallet.get("locked_balance"));
        if (locked.compareTo(amount) < 0) throw new IllegalStateException("Withdrawal ledger is inconsistent for request " + id);
        if ("APPROVED".equals(decision)) {
            db.update("UPDATE wallets SET locked_balance=? WHERE id=?", locked.subtract(amount), wallet.get("id"));
            transaction(wallet, null, "WITHDRAWAL", amount.negate(), locked, locked.subtract(amount), "Withdrawal approved and paid out, request #" + id);
        } else {
            BigDecimal available = money((BigDecimal) wallet.get("available_balance"));
            db.update("UPDATE wallets SET locked_balance=?,available_balance=? WHERE id=?", locked.subtract(amount), available.add(amount), wallet.get("id"));
            transaction(wallet, null, "WITHDRAWAL", amount, available, available.add(amount), "Withdrawal rejected; amount returned, request #" + id);
        }
        db.update("UPDATE withdrawal_requests SET status=?,admin_note=?,reviewed_by_profile_id=?,reviewed_at=CURRENT_TIMESTAMP WHERE id=?",
                decision, clean(request.adminNote()), principal.profileId(), id);
        return Map.of("success", true, "id", id, "status", decision);
    }

    /** Releases bookings that never reached provider approval before their appointment. */
    @Scheduled(fixedDelayString = "${pawcare.wallet.expiry-check-ms:900000}")
    public void releaseExpiredEscrows() {
        for (Map<String, Object> row : db.queryForList("SELECT id FROM bookings WHERE status='PENDING_APPROVAL' AND booking_start < CURRENT_TIMESTAMP")) {
            try {
                expireBooking(((Number) row.get("id")).longValue());
            } catch (RuntimeException error) {
                // One corrupt record must not stop the next expiry pass.
                log.error("Could not release expired escrow for booking {}", row.get("id"), error);
            }
        }
    }

    @Transactional
    public void expireBooking(long bookingId) {
        Map<String, Object> booking = one("SELECT * FROM bookings WHERE id=? FOR UPDATE", bookingId);
        if (booking == null || !"PENDING_APPROVAL".equals(booking.get("status"))) return;
        releaseEscrowForBooking(bookingId, "booking expired before provider approval");
        db.update("UPDATE bookings SET status='CANCELLED',cancel_reason='Expired before provider approval' WHERE id=?", bookingId);
        db.update("INSERT INTO booking_status_history(booking_id,previous_status,new_status,note) VALUES(?,?,?,?)", bookingId, "PENDING_APPROVAL", "CANCELLED", "Escrow released automatically after expiry");
    }

    private void markBookingAwaitingApproval(long bookingId, long customerId, String note) {
        db.update("UPDATE bookings SET status='PENDING_APPROVAL' WHERE id=?", bookingId);
        db.update("INSERT INTO booking_status_history(booking_id,previous_status,new_status,changed_by_profile_id,note) VALUES(?,?,?,?,?)",
                bookingId, "PENDING_PAYMENT", "PENDING_APPROVAL", customerId, note);
        Map<String, Object> provider = one("SELECT p.owner_profile_id FROM bookings b JOIN providers p ON p.id=b.provider_id WHERE b.id=?", bookingId);
        if (provider != null) {
            db.update("INSERT INTO notifications(recipient_profile_id,title,content,notification_type,reference_type,reference_id) VALUES(?,?,?,?,?,?)",
                    provider.get("owner_profile_id"), "Booking chờ duyệt", "Booking #" + bookingId + " đã thanh toán và chờ bạn duyệt.", "BOOKING_STATUS", "BOOKING", bookingId);
        }
    }

    private Map<String, Object> lockWallet(String ownerType, long ownerId) {
        ensureWallet(ownerType, ownerId);
        return one("SELECT * FROM wallets WHERE owner_type=? AND owner_id=? FOR UPDATE", ownerType, ownerId);
    }

    private Map<String, Object> lockWalletById(long id) { return one("SELECT * FROM wallets WHERE id=? FOR UPDATE", id); }
    private Map<String, Object> ensureWallet(String ownerType, long ownerId) {
        db.update("INSERT IGNORE INTO wallets(owner_type,owner_id,available_balance,locked_balance) VALUES(?,?,0,0)", ownerType, ownerId);
        return one("SELECT * FROM wallets WHERE owner_type=? AND owner_id=?", ownerType, ownerId);
    }

    private void transaction(Map<String, Object> wallet, Long bookingId, String type, BigDecimal amount,
                             BigDecimal before, BigDecimal after, String description) {
        db.update("INSERT INTO wallet_transactions(wallet_id,booking_id,type,amount,balance_before,balance_after,description) VALUES(?,?,?,?,?,?,?)",
                wallet.get("id"), bookingId, type, money(amount), money(before), money(after), description);
    }

    private Map<String, Object> walletView(Map<String, Object> wallet) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", wallet.get("id")); result.put("ownerType", wallet.get("owner_type")); result.put("ownerId", wallet.get("owner_id"));
        result.put("availableBalance", wallet.get("available_balance")); result.put("lockedBalance", wallet.get("locked_balance")); result.put("updatedAt", wallet.get("updated_at"));
        return result;
    }
    private Map<String, Object> depositResponse(Map<String, Object> deposit) {
        return Map.of("paymentMethod", "VIETQR", "status", deposit.get("status"), "bookingId", deposit.get("booking_id"),
                "paymentDepositId", deposit.get("id"), "paymentCode", deposit.get("payment_code"), "amount", deposit.get("amount"), "qrUrl", Optional.ofNullable(deposit.get("qr_url")).orElse(""));
    }
    private String qrUrl(String code, BigDecimal amount) {
        if (blank(qrBank) || blank(qrAccount)) return "";
        return "https://img.vietqr.io/image/" + qrBank + "-" + qrAccount + "-compact2.png?amount=" + amount.setScale(0, RoundingMode.HALF_UP).toPlainString()
                + "&addInfo=" + java.net.URLEncoder.encode(code, StandardCharsets.UTF_8)
                + "&accountName=" + java.net.URLEncoder.encode(qrAccountName, StandardCharsets.UTF_8);
    }
    private Map<String, Object> unwrap(Map<String, Object> raw) {
        Object data = raw.get("data");
        if (data instanceof Map<?, ?> map) {
            Map<String, Object> merged = new LinkedHashMap<>(raw);
            map.forEach((k, v) -> merged.put(String.valueOf(k), v));
            return merged;
        }
        return raw;
    }
    private String first(Map<String, Object> data, String... keys) { for (String k : keys) if (data.get(k) != null) return String.valueOf(data.get(k)); return null; }
    private BigDecimal decimal(String value) { try { return blank(value) ? null : new BigDecimal(value.replace(",", "")); } catch (NumberFormatException e) { return null; } }
    private void verifyWebhookToken(String supplied) {
        if (blank(webhookToken)) throw new ApiException(503, "Payment webhook token is not configured");
        if (blank(supplied) || !MessageDigest.isEqual(webhookToken.getBytes(StandardCharsets.UTF_8), supplied.getBytes(StandardCharsets.UTF_8))) throw new ApiException(401, "Invalid payment webhook token");
    }
    private String ownerType(CurrentPrincipal p) { return "PROVIDER".equals(p.role()) ? PROVIDER : "ADMIN".equals(p.role()) ? PLATFORM : USER; }
    private long ownerId(CurrentPrincipal p) { return "PROVIDER".equals(p.role()) ? ((Number) requireOne("SELECT id FROM providers WHERE owner_profile_id=?", p.profileId()).get("id")).longValue() : "ADMIN".equals(p.role()) ? 0L : p.profileId(); }
    private void requireAdmin(CurrentPrincipal p) { if (!"ADMIN".equals(p.role())) throw new ApiException(403, "Admin account required"); }
    private void validateWithdraw(WithdrawRequest r) { if (r == null || r.amount() == null || r.amount().signum() <= 0 || blank(r.bankName()) || blank(r.bankAccountNo()) || blank(r.bankAccountName())) throw new ApiException(400, "amount and bank information are required"); }
    private Map<String, Object> requireOne(String sql, Object... args) { Map<String, Object> x = one(sql, args); if (x == null) throw new ApiException(404, "Required record not found"); return x; }
    private Map<String, Object> one(String sql, Object... args) { List<Map<String, Object>> rows = db.queryForList(sql, args); return rows.isEmpty() ? null : rows.get(0); }
    private long lastId() { return db.queryForObject("SELECT LAST_INSERT_ID()", Long.class); }
    private BigDecimal money(BigDecimal value) { return value == null ? BigDecimal.ZERO.setScale(2) : value.setScale(2, RoundingMode.HALF_UP); }
    private boolean blank(String value) { return value == null || value.isBlank(); }
    private String clean(String value) { return value == null ? null : value.trim(); }
}
