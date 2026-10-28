package com.pawcare.publicapi.auth;

public record CurrentPrincipal(long profileId, String role, String email) {}
