package com.pawcare.publicapi.auth.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.Map;

public record RefreshTokenRequest(@NotBlank String refreshToken) {
    public Map<String, Object> toPayload() { return Map.of("refreshToken", refreshToken); }
}
