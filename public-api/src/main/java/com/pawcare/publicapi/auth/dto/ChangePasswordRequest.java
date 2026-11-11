package com.pawcare.publicapi.auth.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.Map;

public record ChangePasswordRequest(@NotBlank String currentPassword, @NotBlank String newPassword) {
    public Map<String, Object> toPayload() { return Map.of("currentPassword", currentPassword, "newPassword", newPassword); }
}
