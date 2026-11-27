package com.pawcare.publicapi.auth;

import com.pawcare.publicapi.web.ApiException;
import com.pawcare.publicapi.bonita.ProviderApprovalWorkflowOutbox;
import com.pawcare.publicapi.location.LocationService;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.sql.Timestamp;
import java.time.*;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Service
public class AuthService {

    private final JdbcTemplate db;
    private final JwtService jwt;
    private final PasswordService passwords = new PasswordService();
    private final SecureRandom random = new SecureRandom();
    private final long refreshDays;
    private final ProviderApprovalWorkflowOutbox providerApprovalOutbox;
    private final LocationService locations;
    private final TransactionalEmailSender emails;

    public AuthService(
            JdbcTemplate db,
            JwtService jwt,
            ProviderApprovalWorkflowOutbox providerApprovalOutbox,
            LocationService locations,
            TransactionalEmailSender emails,
            @Value("${pawcare.auth.refresh-token-days}") long refreshDays
    ) {
        this.db = db;
        this.jwt = jwt;
        this.providerApprovalOutbox = providerApprovalOutbox;
        this.locations = locations;
        this.emails = emails;
        this.refreshDays = refreshDays;
    }

    @Transactional
    public Map<String, Object> register(Map<String, Object> body) {
        String name = req(body, "fullName");
        String email = normalizeEmail(req(body, "email"));
        String password = req(body, "password");

        String role = Optional.ofNullable(body.get("role"))
                .map(Object::toString)
                .orElse("CUSTOMER")
                .toUpperCase(Locale.ROOT);

        if (!role.equals("CUSTOMER") && !role.equals("PROVIDER")) {
            throw new ApiException(400, "role must be CUSTOMER or PROVIDER");
        }

        String phone = text(body, "phone");
        if (role.equals("PROVIDER")) {
            if (phone == null || !phone.matches("^\\+?\\d{9,13}$")) {
                throw new ApiException(400, "Provider phone must contain 9 to 13 digits");
            }
        }

        validatePassword(password);

        if (db.queryForObject(
                "SELECT COUNT(*) FROM user_profiles WHERE email = ?",
                Integer.class,
                email
        ) > 0) {
            throw new ApiException(409, "Email is already registered");
        }

        db.update("""
                INSERT INTO user_profiles
                    (bonita_user_id, full_name, phone, email, address, role_code,
                     password_hash, is_active, email_verified)
                VALUES (NULL, ?, ?, ?, ?, ?, ?, 1, 0)
                """,
                name,
                phone,
                email,
                text(body, "address"),
                role,
                passwords.hash(password)
        );

        Long id = db.queryForObject(
                "SELECT id FROM user_profiles WHERE email = ?",
                Long.class,
                email
        );

        if (role.equals("PROVIDER")) {
            String providerName = Optional.ofNullable(text(body, "providerName")).orElse(name);
            String providerType = Optional.ofNullable(text(body, "providerType")).orElse("INDIVIDUAL");

            if (!providerType.equals("INDIVIDUAL") && !providerType.equals("SHOP")) {
                throw new ApiException(400, "providerType must be INDIVIDUAL or SHOP");
            }

            db.update("""
                    INSERT INTO providers
                        (owner_profile_id, provider_type, name, phone, email, address, status)
                    VALUES (?, ?, ?, ?, ?, ?, 'PENDING')
                    """,
                    id,
                    providerType,
                    providerName,
                    phone,
                    email,
                    Optional.ofNullable(text(body, "address")).orElse("To be completed")
            );
            Long providerId = db.queryForObject(
                    "SELECT id FROM providers WHERE owner_profile_id=?", Long.class, id);
            providerApprovalOutbox.enqueueStart(providerId);
        }

        return tokenResponse(profile(id));
    }

    public Map<String, Object> login(Map<String, Object> body) {
        String email = normalizeEmail(req(body, "email"));
        String password = req(body, "password");
        requireNotRateLimited("LOGIN", email);

        Map<String, Object> p = one(
                "SELECT * FROM user_profiles WHERE email = ? AND is_active = 1",
                email
        );

        if (p == null
                || p.get("password_hash") == null
                || !passwords.matches(password, p.get("password_hash").toString())) {
            recordFailedAttempt("LOGIN", email);
            throw new ApiException(401, "Email or password is incorrect");
        }
        clearAttempts("LOGIN", email);
        return tokenResponse(p);
    }

    @Transactional
    public Map<String, Object> refresh(Map<String, Object> body) {
        String raw = req(body, "refreshToken");

        Map<String, Object> row = one("""
                SELECT rt.profile_id
                FROM refresh_tokens rt
                WHERE rt.token_hash = ?
                  AND rt.revoked_at IS NULL
                  AND rt.expires_at > CURRENT_TIMESTAMP
                """, hash(raw));

        if (row == null) {
            throw new ApiException(401, "Refresh token is invalid or expired");
        }

        db.update(
                "UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE token_hash = ?",
                hash(raw)
        );

        return tokenResponse(profile(((Number) row.get("profile_id")).longValue()));
    }

    @Transactional
    public void logout(Map<String, Object> body) {
        db.update(
                "UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE token_hash = ?",
                hash(req(body, "refreshToken"))
        );
    }

    public Map<String, Object> me(CurrentPrincipal principal) {
        return publicProfile(profile(principal.profileId()));
    }

    @Transactional
    public Map<String, Object> updateProfile(CurrentPrincipal principal, Map<String, Object> body) {
        Map<String, Object> current = profile(principal.profileId());
        String email = text(body, "email");
        if (email != null && !email.isBlank()) {
            email = normalizeEmail(email);
            Integer used = db.queryForObject("SELECT COUNT(*) FROM user_profiles WHERE email=? AND id<>?", Integer.class, email, principal.profileId());
            if (used != null && used > 0) throw new ApiException(409, "Email is already registered");
        } else email = current.get("email").toString();
        String name = text(body, "fullName");
        if (name == null || name.isBlank()) name = current.get("full_name").toString();
        String address = address(body);
        db.update("""
                UPDATE user_profiles SET full_name=?,email=?,phone=COALESCE(?,phone),
                  address=COALESCE(?,address),address_line1=COALESCE(?,address_line1),
                  ward=COALESCE(?,ward),district=COALESCE(?,district),province=COALESCE(?,province)
                WHERE id=?
                """, name, email, text(body,"phone"), address, text(body,"addressLine1"),
                text(body,"ward"), text(body,"district"), text(body,"province"), principal.profileId());
        if (address != null && !address.equals(current.get("address"))) locations.queueCustomer(principal.profileId());
        return publicProfile(profile(principal.profileId()));
    }

    @Transactional
    public Map<String, Object> changePassword(CurrentPrincipal principal, Map<String, Object> body) {
        String oldPassword = req(body, "currentPassword");
        String newPassword = req(body, "newPassword");
        Map<String, Object> current = profile(principal.profileId());
        Object hash = current.get("password_hash");
        if (hash == null || !passwords.matches(oldPassword, hash.toString())) throw new ApiException(401, "Current password is incorrect");
        validatePassword(newPassword);
        db.update("UPDATE user_profiles SET password_hash=?,password_updated_at=CURRENT_TIMESTAMP WHERE id=?", passwords.hash(newPassword), principal.profileId());
        db.update("UPDATE refresh_tokens SET revoked_at=CURRENT_TIMESTAMP WHERE profile_id=? AND revoked_at IS NULL", principal.profileId());
        sendAfterCommit(AccountEmailFactory.passwordChanged(current.get("email").toString(), current.get("full_name").toString()));
        return Map.of("success", true);
    }

    /** Creates a hashed, expiring token. Delivery is delegated to deployment email infrastructure. */
    @Transactional
    public Map<String, Object> requestPasswordReset(String rawEmail) {
        String email = normalizeEmail(rawEmail);
        requireNotRateLimited("PASSWORD_RESET", email);
        Map<String, Object> account = one("SELECT id,email,full_name FROM user_profiles WHERE email=? AND is_active=1", email);
        if (account != null) {
            String token = issueActionToken(((Number) account.get("id")).longValue(), "PASSWORD_RESET");
            sendAfterCommit(AccountEmailFactory.passwordReset(
                    account.get("email").toString(), account.get("full_name").toString(), actionLinkBase(), token));
        }
        recordAttempt("PASSWORD_RESET", email);
        // Do not disclose whether an account exists, or return/log the raw token.
        return Map.of("accepted", true, "message", "If the account exists, reset instructions will be sent.");
    }

    @Transactional
    public Map<String, Object> resetPassword(String rawToken, String newPassword) {
        validatePassword(newPassword);
        long profileId = consumeActionToken(rawToken, "PASSWORD_RESET");
        db.update("UPDATE user_profiles SET password_hash=?,password_updated_at=CURRENT_TIMESTAMP WHERE id=?", passwords.hash(newPassword), profileId);
        db.update("UPDATE refresh_tokens SET revoked_at=CURRENT_TIMESTAMP WHERE profile_id=? AND revoked_at IS NULL", profileId);
        return Map.of("success", true);
    }

    @Transactional
    public Map<String, Object> requestEmailVerification(CurrentPrincipal principal) {
        Map<String, Object> account = profile(principal.profileId());
        requireNotRateLimited("EMAIL_VERIFY_SEND", String.valueOf(principal.profileId()));
        String code = issueEmailVerificationCode(principal.profileId());
        sendAfterCommit(AccountEmailFactory.verification(
                account.get("email").toString(), account.get("full_name").toString(), code));
        recordAttempt("EMAIL_VERIFY_SEND", String.valueOf(principal.profileId()));
        return Map.of("accepted", true, "message", "A six-digit verification code will be sent.");
    }

    @Transactional
    public Map<String, Object> verifyEmail(CurrentPrincipal principal, String code) {
        String subject = String.valueOf(principal.profileId());
        requireNotRateLimited("EMAIL_VERIFY_CONFIRM", subject);
        Map<String, Object> row = one("SELECT id FROM auth_action_tokens WHERE profile_id=? AND token_hash=? AND purpose='EMAIL_VERIFY' AND used_at IS NULL AND revoked_at IS NULL AND expires_at>CURRENT_TIMESTAMP FOR UPDATE",
                principal.profileId(), hash(code));
        if (row == null) {
            recordFailedAttempt("EMAIL_VERIFY_CONFIRM", subject);
            throw new ApiException(400, "Verification code is invalid or expired");
        }
        db.update("UPDATE auth_action_tokens SET used_at=CURRENT_TIMESTAMP WHERE id=?", row.get("id"));
        db.update("UPDATE user_profiles SET email_verified=1 WHERE id=?", principal.profileId());
        clearAttempts("EMAIL_VERIFY_CONFIRM", subject);
        return Map.of("success", true);
    }

    private Map<String, Object> tokenResponse(Map<String, Object> p) {
        long id = ((Number) p.get("id")).longValue();
        String raw = randomToken();

        db.update("""
                INSERT INTO refresh_tokens (profile_id, token_hash, expires_at)
                VALUES (?, ?, ?)
                """,
                id,
                hash(raw),
                Timestamp.from(Instant.now().plus(Duration.ofDays(refreshDays)))
        );

        Map<String, Object> result = new LinkedHashMap<>();
        result.put(
                "accessToken",
                jwt.accessToken(
                        id,
                        p.get("email").toString(),
                        p.get("role_code").toString()
                )
        );
        result.put("refreshToken", raw);
        result.put("tokenType", "Bearer");
        result.put("profile", publicProfile(p));

        return result;
    }

    private Map<String, Object> profile(long id) {
        Map<String, Object> p = one(
                "SELECT * FROM user_profiles WHERE id = ? AND is_active = 1",
                id
        );

        if (p == null) {
            throw new ApiException(401, "Account is unavailable");
        }

        return p;
    }

    private Map<String, Object> publicProfile(Map<String, Object> p) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", p.get("id"));
        result.put("fullName", p.get("full_name"));
        result.put("email", p.get("email"));
        result.put("phone", p.get("phone"));
        result.put("address", p.get("address"));
        result.put("addressLine1", p.get("address_line1"));
        result.put("ward", p.get("ward"));
        result.put("district", p.get("district"));
        result.put("province", p.get("province"));
        result.put("latitude", p.get("latitude"));
        result.put("longitude", p.get("longitude"));
        result.put("geocodeStatus", p.get("geocode_status"));
        result.put("role", p.get("role_code"));
        result.put("emailVerified", p.get("email_verified"));
        return result;
    }

    private Map<String, Object> one(String sql, Object... values) {
        List<Map<String, Object>> rows = db.queryForList(sql, values);
        return rows.isEmpty() ? null : rows.get(0);
    }

    private String req(Map<String, Object> body, String field) {
        String value = text(body, field);

        if (value == null || value.isBlank()) {
            throw new ApiException(400, field + " is required");
        }

        return value;
    }

    private String text(Map<String, Object> body, String field) {
        Object value = body.get(field);
        return value == null ? null : value.toString().trim();
    }

    private String address(Map<String, Object> body) {
        String joined = java.util.stream.Stream.of(text(body, "addressLine1"), text(body, "ward"), text(body, "district"), text(body, "province"))
                .filter(Objects::nonNull).filter(value -> !value.isBlank()).collect(java.util.stream.Collectors.joining(", "));
        return joined.isBlank() ? text(body, "address") : joined;
    }

    private String normalizeEmail(String email) {
        email = email.toLowerCase(Locale.ROOT);

        if (!email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
            throw new ApiException(400, "email is invalid");
        }

        return email;
    }

    private void validatePassword(String password) {
        if (password.length() < 10
                || !password.matches(".*[A-Za-z].*")
                || !password.matches(".*\\d.*")) {
            throw new ApiException(
                    400,
                    "password must have at least 10 characters including a letter and a number"
            );
        }
    }

    private String randomToken() {
        byte[] bytes = new byte[48];
        random.nextBytes(bytes);

        return Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(bytes);
    }

    private String hash(String value) {
        try {
            byte[] hashed = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));

            return Base64.getUrlEncoder()
                    .withoutPadding()
                    .encodeToString(hashed);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private String issueActionToken(long profileId, String purpose) {
        db.update("UPDATE auth_action_tokens SET revoked_at=CURRENT_TIMESTAMP WHERE profile_id=? AND purpose=? AND used_at IS NULL AND revoked_at IS NULL",
                profileId, purpose);
        String token = randomToken();
        db.update("INSERT INTO auth_action_tokens(profile_id,purpose,token_hash,expires_at) VALUES(?,?,?,DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 30 MINUTE))",
                profileId, purpose, hash(token));
        return token;
    }

    private String issueEmailVerificationCode(long profileId) {
        db.update("UPDATE auth_action_tokens SET revoked_at=CURRENT_TIMESTAMP WHERE profile_id=? AND purpose='EMAIL_VERIFY' AND used_at IS NULL AND revoked_at IS NULL", profileId);
        for (int attempt = 0; attempt < 3; attempt++) {
            String code = String.format(Locale.ROOT, "%06d", random.nextInt(1_000_000));
            try {
                db.update("INSERT INTO auth_action_tokens(profile_id,purpose,token_hash,expires_at) VALUES(?,'EMAIL_VERIFY',?,DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 10 MINUTE))",
                        profileId, hash(code));
                return code;
            } catch (org.springframework.dao.DuplicateKeyException ignored) {
                // A six-digit code colliding with an active hashed value is rare; draw again.
            }
        }
        throw new IllegalStateException("Could not issue a verification code");
    }

    @Value("${pawcare.mail.app-deep-link-base:pawcare://auth}")
    private String mailAppDeepLinkBase;

    private String actionLinkBase() {
        String value = mailAppDeepLinkBase == null ? "" : mailAppDeepLinkBase.trim();
        return value.isBlank() ? "pawcare://auth" : value.replaceAll("/+$", "");
    }

    private void sendAfterCommit(TransactionalEmail message) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { emails.send(message); }
        });
    }

    private long consumeActionToken(String rawToken, String purpose) {
        Map<String, Object> row = one("SELECT id,profile_id FROM auth_action_tokens WHERE token_hash=? AND purpose=? AND used_at IS NULL AND revoked_at IS NULL AND expires_at>CURRENT_TIMESTAMP FOR UPDATE",
                hash(rawToken), purpose);
        if (row == null) throw new ApiException(400, "Token is invalid or expired");
        db.update("UPDATE auth_action_tokens SET used_at=CURRENT_TIMESTAMP WHERE id=?", row.get("id"));
        return ((Number) row.get("profile_id")).longValue();
    }

    private void requireNotRateLimited(String action, String subject) {
        Map<String, Object> row = one("SELECT blocked_until FROM auth_rate_limits WHERE action_type=? AND subject_hash=?", action, hash(subject));
        if (row != null && row.get("blocked_until") instanceof Timestamp blocked && blocked.toInstant().isAfter(Instant.now())) {
            throw new ApiException(429, "Too many attempts. Try again later.");
        }
    }

    private void recordFailedAttempt(String action, String subject) { recordAttempt(action, subject); }

    private void recordAttempt(String action, String subject) {
        String subjectHash = hash(subject);
        db.update("INSERT INTO auth_rate_limits(action_type,subject_hash,window_started_at,attempt_count) VALUES(?,?,CURRENT_TIMESTAMP,1) "
                        + "ON DUPLICATE KEY UPDATE attempt_count=IF(window_started_at < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 15 MINUTE),1,attempt_count+1),"
                        + "window_started_at=IF(window_started_at < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 15 MINUTE),CURRENT_TIMESTAMP,window_started_at),"
                        + "blocked_until=IF(attempt_count+1>=5,DATE_ADD(CURRENT_TIMESTAMP,INTERVAL 15 MINUTE),blocked_until)",
                action, subjectHash);
    }

    private void clearAttempts(String action, String subject) {
        db.update("DELETE FROM auth_rate_limits WHERE action_type=? AND subject_hash=?", action, hash(subject));
    }
}
