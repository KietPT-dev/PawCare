package com.pawcare.publicapi.bonita;

/**
 * Boundary around Bonita REST.  Keeping it isolated prevents Bonita outages
 * from corrupting PawCare's booking and escrow transaction.
 */
public interface BonitaBookingGateway {
    void synchronize(long bookingId, BookingWorkflowEvent event) throws Exception;
}
