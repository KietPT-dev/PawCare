package com.pawcare.publicapi.web;

import java.util.Map;

public class ApiException extends RuntimeException {
    private final int status;
    private final String code;
    private final Map<String, Object> details;

    public ApiException(int status, String message) {
        this(status, message, null, Map.of());
    }

    public ApiException(int status, String message, String code, Map<String, Object> details) {
        super(message);
        this.status = status;
        this.code = code;
        this.details = details == null ? Map.of() : Map.copyOf(details);
    }
    public int status() { return status; }
    public String code() { return code; }
    public Map<String, Object> details() { return details; }
}
