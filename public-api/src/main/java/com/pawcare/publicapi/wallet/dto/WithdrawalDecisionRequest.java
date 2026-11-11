package com.pawcare.publicapi.wallet.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record WithdrawalDecisionRequest(
        @NotBlank(message = "is required")
        @Pattern(regexp = "(?i)APPROVED|REJECTED|PROCESSING|PAID|FAILED", message = "must be APPROVED, REJECTED, PROCESSING, PAID or FAILED") String status,
        @Size(max = 1000, message = "must not exceed 1000 characters") String adminNote,
        @Size(max = 160, message = "must not exceed 160 characters") String payoutReference
) {}
