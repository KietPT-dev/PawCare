package com.pawcare.publicapi.auth;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pawcare.publicapi.web.ApiException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.*;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
    private final ObjectMapper json;
    private final byte[] secret;
    private final String issuer;
    private final long accessMinutes;

    public JwtService(ObjectMapper json, @Value("${pawcare.auth.secret}") String encodedSecret,
                      @Value("${pawcare.auth.issuer}") String issuer,
                      @Value("${pawcare.auth.access-token-minutes}") long accessMinutes) {
        this.json = json; this.issuer = issuer; this.accessMinutes = accessMinutes;
        if (encodedSecret.startsWith("CHANGE_ME")) throw new IllegalStateException("PAWCARE_JWT_SECRET must be configured");
        this.secret = Base64.getDecoder().decode(encodedSecret);
        if (secret.length < 32) throw new IllegalStateException("PAWCARE_JWT_SECRET must decode to at least 32 bytes");
    }
    public String accessToken(long profileId, String email, String role) {
        long now = Instant.now().getEpochSecond();
        return sign(Map.of("sub", String.valueOf(profileId), "email", email, "role", role,
                           "iss", issuer, "iat", now, "exp", now + accessMinutes * 60, "typ", "access"));
    }
    public CurrentPrincipal verifyAccess(String token) {
        try {
            String[] p = token.split("\\.");
            if (p.length != 3 || !constantEquals(p[2], signature(p[0] + "." + p[1]))) throw new ApiException(401, "Invalid access token");
            Map<String,Object> claims = json.readValue(decode(p[1]), new TypeReference<>() {});
            if (!issuer.equals(claims.get("iss")) || !"access".equals(claims.get("typ")) ||
                Instant.now().getEpochSecond() >= ((Number) claims.get("exp")).longValue()) throw new ApiException(401, "Access token expired");
            return new CurrentPrincipal(Long.parseLong((String) claims.get("sub")), (String) claims.get("role"), (String) claims.get("email"));
        } catch (ApiException e) { throw e; }
          catch (Exception e) { throw new ApiException(401, "Invalid access token"); }
    }
    private String sign(Map<String,Object> claims) {
        try {
            String h = encode(json.writeValueAsBytes(Map.of("alg","HS256","typ","JWT")));
            String p = encode(json.writeValueAsBytes(claims));
            return h + "." + p + "." + signature(h + "." + p);
        } catch (Exception e) { throw new IllegalStateException("JWT creation failed", e); }
    }
    private String signature(String value) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256"); mac.init(new SecretKeySpec(secret, "HmacSHA256"));
            return encode(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) { throw new IllegalStateException("JWT signing failed", e); }
    }
    private String encode(byte[] bytes) { return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes); }
    private byte[] decode(String s) { return Base64.getUrlDecoder().decode(s); }
    private boolean constantEquals(String a, String b) { return java.security.MessageDigest.isEqual(a.getBytes(StandardCharsets.UTF_8), b.getBytes(StandardCharsets.UTF_8)); }
}
