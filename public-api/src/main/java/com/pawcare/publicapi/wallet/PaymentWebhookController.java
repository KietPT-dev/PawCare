package com.pawcare.publicapi.wallet;

import java.util.Map;
import org.springframework.web.bind.annotation.*;

/** Public callback endpoint for an authenticated bank-notification relay. */
@RestController
@RequestMapping({"/api/payments", "/api/v1/payments"})
public class PaymentWebhookController {
    private final WalletService wallets;

    public PaymentWebhookController(WalletService wallets) { this.wallets = wallets; }

    @PostMapping("/webhook")
    public Map<String, Object> receive(
            @RequestHeader(value = "X-PawCare-Webhook-Token", required = false) String internalToken,
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @RequestBody Map<String, Object> payload) {
        // SePay normally uses Authorization. The service removes an Apikey or
        // Bearer scheme before comparing it with the configured secret.
        String token = internalToken == null || internalToken.isBlank() ? authorization : internalToken;
        return wallets.processBankWebhook(token, payload);
    }
}
