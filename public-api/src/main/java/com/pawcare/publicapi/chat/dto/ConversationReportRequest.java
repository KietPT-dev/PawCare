package com.pawcare.publicapi.chat.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ConversationReportRequest(
        @NotBlank @Size(max = 64) String category,
        @Size(max = 1000) String note) { }
