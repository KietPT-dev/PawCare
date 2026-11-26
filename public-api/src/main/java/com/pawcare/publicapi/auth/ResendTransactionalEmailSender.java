package com.pawcare.publicapi.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/** Resend adapter. Sending failures are deliberately non-fatal to auth flows. */
@Service
public class ResendTransactionalEmailSender implements TransactionalEmailSender {
    private static final Logger log = LoggerFactory.getLogger(ResendTransactionalEmailSender.class);
    private final ObjectMapper json;
    private final HttpClient http;
    private final String provider;
    private final String apiKey;
    private final String from;
    private final String replyTo;

    public ResendTransactionalEmailSender(
            ObjectMapper json,
            @Value("${pawcare.mail.provider:DISABLED}") String provider,
            @Value("${pawcare.mail.resend-api-key:}") String apiKey,
            @Value("${pawcare.mail.from:}") String from,
            @Value("${pawcare.mail.reply-to:}") String replyTo) {
        this.json = json;
        this.http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
        this.provider = provider == null ? "DISABLED" : provider.trim().toUpperCase();
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.from = from == null ? "" : from.trim();
        this.replyTo = replyTo == null ? "" : replyTo.trim();
    }

    @Override
    public void send(TransactionalEmail message) {
        if (!"RESEND".equals(provider)) {
            log.info("Transactional email skipped: provider disabled, template={}", message.template());
            return;
        }
        if (apiKey.isBlank() || !validFrom(from)) {
            log.warn("Transactional email skipped: Resend mail configuration is incomplete, template={}", message.template());
            return;
        }
        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("from", from);
            payload.put("to", new String[] {message.recipient()});
            payload.put("subject", message.subject());
            payload.put("text", message.textBody());
            payload.put("html", message.htmlBody());
            if (!replyTo.isBlank()) payload.put("reply_to", replyTo);
            HttpRequest request = HttpRequest.newBuilder(URI.create("https://api.resend.com/emails"))
                    .timeout(Duration.ofSeconds(10))
                    .header("Authorization", "Bearer " + apiKey)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(payload)))
                    .build();
            int status = http.send(request, HttpResponse.BodyHandlers.discarding()).statusCode();
            if (status / 100 == 2) log.info("Transactional email accepted by provider, template={}", message.template());
            else log.warn("Transactional email provider rejected request, template={}, status={}", message.template(), status);
        } catch (Exception exception) {
            log.warn("Transactional email delivery failed, template={}, reason={}", message.template(), exception.getClass().getSimpleName());
        }
    }

    private boolean validFrom(String candidate) {
        return candidate.matches("^[^<>@\\s]+(?: [^<>]*)? <[^<>@\\s]+@[^<>@\\s]+>$") || candidate.matches("^[^<>@\\s]+@[^<>@\\s]+$");
    }
}
