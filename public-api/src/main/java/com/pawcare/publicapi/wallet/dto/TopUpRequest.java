package com.pawcare.publicapi.wallet.dto;

import java.math.BigDecimal;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

public record TopUpRequest(
        @NotNull(message = "is required")
        @DecimalMin(value = "0.01", message = "must be greater than zero")
        BigDecimal amount
) {}
