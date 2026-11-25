package com.pawcare.publicapi.bonita.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

/** Callback payload sent only by the two service tasks in ProviderApproval. */
public record ProviderApprovalCallbackRequest(
        @Positive long providerId,
        @NotBlank @Pattern(regexp = "(?i)APPROVED|REJECTED", message = "decision must be APPROVED or REJECTED") String decision,
        @Size(max = 2000, message = "reviewNote must not exceed 2000 characters") String reviewNote,
        @Positive Long caseId) {
}
