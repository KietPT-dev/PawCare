package com.pawcare.publicapi.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import java.util.LinkedHashMap;
import java.util.Map;

/** Public registration payload. Optional provider fields are used only for PROVIDER. */
public record RegisterRequest(
        @NotBlank String fullName,
        @NotBlank @Email String email,
        @NotBlank String password,
        String phone,
        String address,
        String role,
        String providerName,
        String providerType
) {
    public Map<String, Object> toPayload() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("fullName", fullName);
        result.put("email", email);
        result.put("password", password);
        result.put("phone", phone);
        result.put("address", address);
        result.put("role", role);
        result.put("providerName", providerName);
        result.put("providerType", providerType);
        return result;
    }
}
