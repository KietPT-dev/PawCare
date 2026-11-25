package com.pawcare.publicapi.bonita;

/** Bonita transport boundary; PawCare remains the provider-status source of truth. */
public interface BonitaProviderApprovalGateway {
    void startApprovalCase(long providerId) throws Exception;
    void submitDecision(long providerId, String decision, String reviewNote) throws Exception;
}
