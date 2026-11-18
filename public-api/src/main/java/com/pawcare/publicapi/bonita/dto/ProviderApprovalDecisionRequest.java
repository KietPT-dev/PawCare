package com.pawcare.publicapi.bonita.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Decision submitted by an administrator; Bonita remains responsible for completing the task. */
public record ProviderApprovalDecisionRequest(
        @NotBlank @Pattern(regexp = "(?i)APPROVED|REJECTED", message = "decision must be APPROVED or REJECTED") String decision,
        @Size(max = 2000, message = "reviewNote must not exceed 2000 characters") String reviewNote) {
}
