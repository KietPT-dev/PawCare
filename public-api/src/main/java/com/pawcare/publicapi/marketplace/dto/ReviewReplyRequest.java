package com.pawcare.publicapi.marketplace.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Provider-facing response to one review. The review ownership is checked server-side. */
public record ReviewReplyRequest(
        @NotBlank(message = "content is required")
        @Size(max = 5000, message = "content must be at most 5000 characters")
        String content) {
}
