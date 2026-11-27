package com.pawcare.publicapi.ai;

import java.util.List;
import java.util.Map;

/** Allow-list shared by the internal AI endpoint and outbox producer. */
final class AiRiskFeatures {
    static final List<String> MODEL_FEATURES = List.of("amount", "hourOfDay", "dayOfWeek", "accountAgeDays",
            "transactionCount10m", "transactionCount1h", "transactionCount24h", "amountSum24h", "priorFailedAttempts");
    static final List<String> RESPONSE_FEATURES = List.of("amount", "hourOfDay", "dayOfWeek", "accountAgeDays",
            "transactionCount10m", "transactionCount1h", "transactionCount24h", "amountSum24h", "priorFailedAttempts", "eventAgeSeconds");
    private AiRiskFeatures() { }
    static Map<String,Object> allow(Map<String,Object> source) {
        var safe=new java.util.LinkedHashMap<String,Object>();
        for (String key : MODEL_FEATURES) if (source.get(key) instanceof Number) safe.put(key, source.get(key));
        return safe;
    }
}
