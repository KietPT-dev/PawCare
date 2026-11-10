package com.pawcare.publicapi.health;

import java.time.Instant;
import java.util.Map;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** Deliberately small liveness/readiness endpoint; it never exposes database details. */
@RestController
public class HealthController {
    private final JdbcTemplate db;
    public HealthController(JdbcTemplate db) { this.db = db; }

    @GetMapping("/api/v1/health")
    public ResponseEntity<Map<String, Object>> health() {
        try {
            db.queryForObject("SELECT 1", Integer.class);
            return ResponseEntity.ok(Map.of("status", "UP", "database", "UP", "timestamp", Instant.now().toString()));
        } catch (DataAccessException failure) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("status", "DOWN", "database", "DOWN", "timestamp", Instant.now().toString()));
        }
    }
}
