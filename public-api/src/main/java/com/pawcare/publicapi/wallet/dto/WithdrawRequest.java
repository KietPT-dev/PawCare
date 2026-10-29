package com.pawcare.publicapi.wallet.dto;

import java.math.BigDecimal;

public record WithdrawRequest(
        BigDecimal amount,
        String bankName,
        String bankAccountNo,
        String bankAccountName,
        Long bonitaCaseId
) {}
