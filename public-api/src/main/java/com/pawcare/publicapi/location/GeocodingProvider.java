package com.pawcare.publicapi.location;

public interface GeocodingProvider {
    GeocodingResult geocode(String address);
}
