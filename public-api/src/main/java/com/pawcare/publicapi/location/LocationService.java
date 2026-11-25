package com.pawcare.publicapi.location;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LocationService {
    private final JdbcTemplate db;
    private final Optional<GeocodingProvider> geocodingProvider;

    public LocationService(JdbcTemplate db, ObjectProvider<GeocodingProvider> geocodingProvider) {
        this.db = db;
        this.geocodingProvider = Optional.ofNullable(geocodingProvider.getIfAvailable());
    }

    @Transactional
    public void queueCustomer(long profileId) {
        db.update("UPDATE user_profiles SET latitude=NULL,longitude=NULL,geocode_status='PENDING',geocode_error=NULL,geocoded_at=NULL WHERE id=?", profileId);
    }

    @Transactional
    public void queueProvider(long providerId) {
        db.update("UPDATE providers SET latitude=NULL,longitude=NULL,geocode_status='PENDING',geocode_error=NULL,geocoded_at=NULL WHERE id=?", providerId);
    }

    @Scheduled(fixedDelayString = "${pawcare.geocoding.retry-delay-ms:60000}")
    public void geocodePending() {
        geocode("user_profiles", "id", "SELECT id,address FROM user_profiles WHERE geocode_status='PENDING' AND address IS NOT NULL ORDER BY updated_at LIMIT 25");
        geocode("providers", "id", "SELECT id,address FROM providers WHERE geocode_status='PENDING' AND address IS NOT NULL ORDER BY updated_at LIMIT 25");
    }

    private void geocode(String table, String idColumn, String query) {
        for (Map<String, Object> row : db.queryForList(query)) {
            long id = ((Number) row.get("id")).longValue();
            String address = String.valueOf(row.get("address"));
            GeocodingResult result = geocodingProvider
                    .map(provider -> provider.geocode(address))
                    .orElseGet(() -> GeocodingResult.failed("NOT_CONFIGURED", "Geocoding provider is not configured"));
            if ("RESOLVED".equals(result.status())) {
                db.update("UPDATE " + table + " SET latitude=?,longitude=?,geocode_status='RESOLVED',geocode_error=NULL,geocoded_at=CURRENT_TIMESTAMP WHERE " + idColumn + "=? AND geocode_status='PENDING'",
                        result.latitude(), result.longitude(), id);
            } else {
                db.update("UPDATE " + table + " SET geocode_status=?,geocode_error=?,geocoded_at=CURRENT_TIMESTAMP WHERE " + idColumn + "=? AND geocode_status='PENDING'",
                        result.status(), safeError(result.error()), id);
            }
        }
    }

    private String safeError(String value) {
        if (value == null) return null;
        return value.length() <= 500 ? value : value.substring(0, 500);
    }
}
