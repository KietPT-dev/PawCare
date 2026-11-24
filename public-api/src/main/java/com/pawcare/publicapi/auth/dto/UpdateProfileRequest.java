package com.pawcare.publicapi.auth.dto;

import jakarta.validation.constraints.Email;
import java.util.LinkedHashMap;
import java.util.Map;

public record UpdateProfileRequest(String fullName, @Email String email, String phone, String address,
                                   String addressLine1, String ward, String district, String province) {
    public Map<String, Object> toPayload() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("fullName", fullName);
        result.put("email", email);
        result.put("phone", phone);
        result.put("address", address);
        result.put("addressLine1", addressLine1);
        result.put("ward", ward);
        result.put("district", district);
        result.put("province", province);
        return result;
    }
}
