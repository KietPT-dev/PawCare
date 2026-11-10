package com.pawcare.publicapi.marketplace.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Input for a provider/customer booking-state transition. */
public record BookingStatusRequest(
        @NotBlank(message = "is required") String status,
        @Size(max = 1000, message = "must not exceed 1000 characters") String cancelReason,
        @Size(max = 2000, message = "must not exceed 2000 characters") String providerNote,
        @Size(max = 2000, message = "must not exceed 2000 characters") String note
) {}
