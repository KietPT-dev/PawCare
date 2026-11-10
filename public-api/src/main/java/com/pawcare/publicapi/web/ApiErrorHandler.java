package com.pawcare.publicapi.web;

import java.time.Instant;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestControllerAdvice
public class ApiErrorHandler {
    private static final Logger log = LoggerFactory.getLogger(ApiErrorHandler.class);
    @ExceptionHandler(ApiException.class)
    ResponseEntity<Map<String, Object>> known(ApiException e) {
        return ResponseEntity.status(e.status()).body(Map.of(
                "status", e.status(), "error", e.getMessage(), "timestamp", Instant.now().toString()));
    }
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    Map<String, Object> unknown(Exception e) {
        log.error("Unhandled API error: {}", e.toString(), e);
        return Map.of("status", 500, "error", "Internal server error", "timestamp", Instant.now().toString());
    }
}
