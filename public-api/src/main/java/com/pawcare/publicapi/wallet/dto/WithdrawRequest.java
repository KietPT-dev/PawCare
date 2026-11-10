package com.pawcare.publicapi.wallet.dto;

import java.math.BigDecimal;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record WithdrawRequest(
        @NotNull(message = "is required") @DecimalMin(value = "0.01", message = "must be greater than zero") BigDecimal amount,
        @NotBlank(message = "is required") @Size(max = 100) String bankName,
        @NotBlank(message = "is required") @Size(max = 64) String bankAccountNo,
        @NotBlank(message = "is required") @Size(max = 150) String bankAccountName,
        Long bonitaCaseId
) {}
