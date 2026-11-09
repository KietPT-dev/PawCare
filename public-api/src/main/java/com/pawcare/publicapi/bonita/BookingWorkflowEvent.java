package com.pawcare.publicapi.bonita;

/** Events emitted by PawCare after its own transaction commits. */
public enum BookingWorkflowEvent {
    START,
    PROVIDER_APPROVED,
    PROVIDER_REJECTED,
    PROVIDER_SERVICE_DONE,
    CUSTOMER_CONFIRMED,
    CUSTOMER_DISPUTED,
    ADMIN_RELEASE_TO_PROVIDER,
    ADMIN_REFUND_TO_CUSTOMER,
    CANCELLED,
    EXPIRED
}
