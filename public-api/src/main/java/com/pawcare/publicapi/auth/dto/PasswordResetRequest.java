package com.pawcare.publicapi.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record PasswordResetRequest(@NotBlank String token, @NotBlank String newPassword) { }
