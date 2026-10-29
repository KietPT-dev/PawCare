package com.pawcare.publicapi.wallet.dto;

import java.util.Map;

/**
 * Deliberately accepts a provider-neutral payload. SePay and PayOS use
 * different field names, so WalletService normalises their common fields.
 */
public record BankWebhookRequest(Map<String, Object> payload) {}
