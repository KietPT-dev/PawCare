package com.pawcare.publicapi.wallet.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record WithdrawalDecisionRequest(
        @NotBlank(message = "is required")
        @Pattern(regexp = "(?i)APPROVED|REJECTED", message = "must be APPROVED or REJECTED") String status,
        @Size(max = 1000, message = "must not exceed 1000 characters") String adminNote
) {}
