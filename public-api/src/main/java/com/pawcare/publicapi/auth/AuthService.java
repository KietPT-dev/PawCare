package com.pawcare.publicapi.auth;

import com.pawcare.publicapi.web.ApiException;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.sql.Timestamp;
import java.time.*;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final JdbcTemplate db;
    private final JwtService jwt;
    private final PasswordService passwords = new PasswordService();
    private final SecureRandom random = new SecureRandom();
    private final long refreshDays;

    public AuthService(
            JdbcTemplate db,
            JwtService jwt,
            @Value("${pawcare.auth.refresh-token-days}") long refreshDays
    ) {
        this.db = db;
        this.jwt = jwt;
        this.refreshDays = refreshDays;
    }

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
                text(body, "phone"),
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
                    text(body, "phone"),
                    email,
                    Optional.ofNullable(text(body, "address")).orElse("To be completed")
            );
        }

        return tokenResponse(profile(id));
    }

    public Map<String, Object> login(Map<String, Object> body) {
        String email = normalizeEmail(req(body, "email"));
        String password = req(body, "password");

        Map<String, Object> p = one(
                "SELECT * FROM user_profiles WHERE email = ? AND is_active = 1",
                email
        );

        if (p == null
                || p.get("password_hash") == null
                || !passwords.matches(password, p.get("password_hash").toString())) {
            throw new ApiException(401, "Email or password is incorrect");
        }

        return tokenResponse(p);
    }

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

    public void logout(Map<String, Object> body) {
        db.update(
                "UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE token_hash = ?",
                hash(req(body, "refreshToken"))
        );
    }

    public Map<String, Object> me(CurrentPrincipal principal) {
        return publicProfile(profile(principal.profileId()));
    }

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
        db.update("UPDATE user_profiles SET full_name=?,email=?,phone=COALESCE(?,phone),address=COALESCE(?,address) WHERE id=?",
            name, email, text(body,"phone"), text(body,"address"), principal.profileId());
        return publicProfile(profile(principal.profileId()));
    }

    public Map<String, Object> changePassword(CurrentPrincipal principal, Map<String, Object> body) {
        String oldPassword = req(body, "currentPassword");
        String newPassword = req(body, "newPassword");
        Map<String, Object> current = profile(principal.profileId());
        Object hash = current.get("password_hash");
        if (hash == null || !passwords.matches(oldPassword, hash.toString())) throw new ApiException(401, "Current password is incorrect");
        validatePassword(newPassword);
        db.update("UPDATE user_profiles SET password_hash=?,password_updated_at=CURRENT_TIMESTAMP WHERE id=?", passwords.hash(newPassword), principal.profileId());
        db.update("UPDATE refresh_tokens SET revoked_at=CURRENT_TIMESTAMP WHERE profile_id=? AND revoked_at IS NULL", principal.profileId());
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
}
