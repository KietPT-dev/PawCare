package com.pawcare.publicapi.chat.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UpdateConversationReportRequest(
        @NotBlank
        @Pattern(regexp = "OPEN|REVIEWED|DISMISSED", flags = Pattern.Flag.CASE_INSENSITIVE)
        String status,
        @Size(max = 1000) String reviewerNote) {
}
