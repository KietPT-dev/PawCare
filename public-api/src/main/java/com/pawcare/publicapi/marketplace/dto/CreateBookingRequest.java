package com.pawcare.publicapi.marketplace.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

/**
 * Customer request used to create a booking.  Keeping this contract typed
 * prevents malformed client input from reaching ledger/escrow operations.
 */
public record CreateBookingRequest(
        @NotNull @Positive Long petId,
        @NotNull @Positive Long providerId,
        @NotNull @Positive Long serviceId,
        @Positive Long staffId,
        @NotBlank @Size(max = 40) String bookingStart,
        @NotBlank @Pattern(regexp = "(?i)WALLET|VIETQR",
                message = "paymentMethod must be WALLET or VIETQR") String paymentMethod,
        @Size(max = 2000) String customerNote
) {
}
