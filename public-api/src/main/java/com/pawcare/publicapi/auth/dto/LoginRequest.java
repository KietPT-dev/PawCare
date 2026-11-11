package com.pawcare.publicapi.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import java.util.Map;

public record LoginRequest(@NotBlank @Email String email, @NotBlank String password) {
    public Map<String, Object> toPayload() { return Map.of("email", email, "password", password); }
}
