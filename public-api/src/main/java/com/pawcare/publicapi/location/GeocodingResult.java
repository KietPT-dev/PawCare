package com.pawcare.publicapi.location;

import java.math.BigDecimal;

public record GeocodingResult(String status, BigDecimal latitude, BigDecimal longitude, String error) {
    public static GeocodingResult resolved(BigDecimal latitude, BigDecimal longitude) {
        return new GeocodingResult("RESOLVED", latitude, longitude, null);
    }

    public static GeocodingResult failed(String status, String error) {
        return new GeocodingResult(status, null, null, error);
    }
}
