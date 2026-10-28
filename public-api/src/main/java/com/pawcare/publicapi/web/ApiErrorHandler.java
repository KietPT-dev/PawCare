package com.pawcare.publicapi.web;

import java.time.Instant;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestControllerAdvice
public class ApiErrorHandler {
    @ExceptionHandler(ApiException.class)
    @ResponseStatus
    Map<String, Object> known(ApiException e) {
        return Map.of("status", e.status(), "error", e.getMessage(), "timestamp", Instant.now().toString());
    }
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    Map<String, Object> unknown(Exception e) {
        return Map.of("status", 500, "error", "Internal server error", "timestamp", Instant.now().toString());
    }
}
