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
        // SePay's API-key mode sends `Authorization: Apikey <key>`. Keep the
        // project-specific header as a convenient option for local relays/tests.
        String token = internalToken;
        if ((token == null || token.isBlank()) && authorization != null
                && authorization.regionMatches(true, 0, "Apikey ", 0, 7)) {
            token = authorization.substring(7).trim();
        }
        return wallets.processBankWebhook(token, payload);
    }
}
