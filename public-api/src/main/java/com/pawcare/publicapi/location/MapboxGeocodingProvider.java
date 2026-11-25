package com.pawcare.publicapi.location;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/** Optional production adapter. It is not created unless Mapbox is explicitly configured. */
@Component
@ConditionalOnProperty(name = "pawcare.geocoding.provider", havingValue = "MAPBOX")
public class MapboxGeocodingProvider implements GeocodingProvider {
    private final ObjectMapper json;
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
    private final String token;

    public MapboxGeocodingProvider(ObjectMapper json, @Value("${pawcare.geocoding.api-key:}") String token) {
        this.json = json;
        this.token = token;
    }

    @Override
    public GeocodingResult geocode(String address) {
        if (token.isBlank()) return GeocodingResult.failed("NOT_CONFIGURED", "Mapbox API key is not configured");
        try {
            String query = URLEncoder.encode(address, StandardCharsets.UTF_8);
            URI uri = URI.create("https://api.mapbox.com/search/geocode/v6/forward?q=" + query + "&limit=1&access_token=" + URLEncoder.encode(token, StandardCharsets.UTF_8));
            HttpRequest request = HttpRequest.newBuilder(uri).timeout(Duration.ofSeconds(10)).GET().build();
            HttpResponse<String> response = http.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) return GeocodingResult.failed("FAILED", "Mapbox geocoding request failed");
            JsonNode coordinates = json.readTree(response.body()).path("features").path(0).path("geometry").path("coordinates");
            if (!coordinates.isArray() || coordinates.size() < 2) return GeocodingResult.failed("NOT_FOUND", "Address could not be geocoded");
            return GeocodingResult.resolved(BigDecimal.valueOf(coordinates.get(1).asDouble()), BigDecimal.valueOf(coordinates.get(0).asDouble()));
        } catch (Exception ignored) {
            return GeocodingResult.failed("FAILED", "Geocoding provider is temporarily unavailable");
        }
    }
}
