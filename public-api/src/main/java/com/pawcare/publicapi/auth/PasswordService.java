package com.pawcare.publicapi.auth;

import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

public class PasswordService {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int ITERATIONS = 210_000;
    private static final int KEY_BITS = 256;

    public String hash(String password) {
        byte[] salt = new byte[16]; RANDOM.nextBytes(salt);
        return "pbkdf2-sha256$" + ITERATIONS + "$" + b64(salt) + "$" + b64(derive(password.toCharArray(), salt, ITERATIONS));
    }
    public boolean matches(String password, String encoded) {
        try {
            String[] parts = encoded.split("\\$");
            if (parts.length != 4 || !"pbkdf2-sha256".equals(parts[0])) return false;
            byte[] expected = Base64.getUrlDecoder().decode(parts[3]);
            byte[] actual = derive(password.toCharArray(), Base64.getUrlDecoder().decode(parts[2]), Integer.parseInt(parts[1]));
            return java.security.MessageDigest.isEqual(expected, actual);
        } catch (Exception ignored) { return false; }
    }
    private byte[] derive(char[] password, byte[] salt, int iterations) {
        try {
            return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
                .generateSecret(new PBEKeySpec(password, salt, iterations, KEY_BITS)).getEncoded();
        } catch (Exception e) { throw new IllegalStateException("Password hashing unavailable", e); }
    }
    private String b64(byte[] value) { return Base64.getUrlEncoder().withoutPadding().encodeToString(value); }
}
