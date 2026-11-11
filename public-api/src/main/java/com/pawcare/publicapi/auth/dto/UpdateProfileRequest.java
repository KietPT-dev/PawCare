package com.pawcare.publicapi.auth.dto;

import jakarta.validation.constraints.Email;
import java.util.LinkedHashMap;
import java.util.Map;

public record UpdateProfileRequest(String fullName, @Email String email, String phone, String address) {
    public Map<String, Object> toPayload() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("fullName", fullName);
        result.put("email", email);
        result.put("phone", phone);
        result.put("address", address);
        return result;
    }
}
