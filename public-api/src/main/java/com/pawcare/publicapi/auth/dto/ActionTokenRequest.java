package com.pawcare.publicapi.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record ActionTokenRequest(@NotBlank String token) { }
