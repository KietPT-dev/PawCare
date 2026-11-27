package com.pawcare.publicapi.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/** A short-lived code is verified only for the authenticated account. */
public record EmailVerificationCodeRequest(
        @NotBlank @Pattern(regexp = "\\d{6}", message = "must contain exactly 6 digits") String code
) { }
