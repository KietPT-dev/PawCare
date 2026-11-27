package com.pawcare.publicapi.ai;

import java.util.List;
import java.util.Map;

/** Allow-list shared by the internal AI endpoint and outbox producer. */
final class AiRiskFeatures {
    static final List<String> MODEL_FEATURES = List.of("amount", "hourOfDay", "dayOfWeek", "accountAgeDays",
            "transactionCount10m", "transactionCount1h", "transactionCount24h", "amountSum24h", "priorFailedAttempts");
    static final List<String> RESPONSE_FEATURES = List.of("amount", "hourOfDay", "dayOfWeek", "accountAgeDays",
            "transactionCount10m", "transactionCount1h", "transactionCount24h", "amountSum24h", "priorFailedAttempts", "eventAgeSeconds");
    static final List<String> RESULT_FEATURES = List.of("amount", "hour_of_day", "day_of_week", "account_age_days",
            "transaction_count_10m", "transaction_count_1h", "transaction_count_24h", "amount_sum_24h", "prior_failed_attempts");
    private AiRiskFeatures() { }
    static Map<String,Object> allow(Map<String,Object> source) {
        var safe=new java.util.LinkedHashMap<String,Object>();
        for (String key : MODEL_FEATURES) if (source.get(key) instanceof Number) safe.put(key, source.get(key));
        return safe;
    }
    static Map<String,Object> resultAllow(Map<?,?> source) {
        var safe=new java.util.LinkedHashMap<String,Object>();
        for (String key : RESULT_FEATURES) if (source.get(key) instanceof Number) safe.put(key, source.get(key));
        return safe;
    }
}
