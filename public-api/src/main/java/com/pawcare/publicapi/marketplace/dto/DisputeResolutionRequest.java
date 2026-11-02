package com.pawcare.publicapi.marketplace.dto;

/** Admin's final escrow decision for a disputed booking. */
public record DisputeResolutionRequest(String action, String adminNote) {}
