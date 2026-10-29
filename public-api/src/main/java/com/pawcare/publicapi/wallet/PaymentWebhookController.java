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
            @RequestHeader(value = "X-PawCare-Webhook-Token", required = false) String token,
            @RequestBody Map<String, Object> payload) {
        return wallets.processBankWebhook(token, payload);
    }
}
