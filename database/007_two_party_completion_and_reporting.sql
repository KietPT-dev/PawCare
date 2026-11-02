-- PawCare two-party completion workflow and reporting indexes.
-- Run ONCE in DBeaver after migrations 001 through 006.
USE pawcare;

-- Provider reports completion; customer confirmation (or admin dispute decision)
-- is required before escrow can be settled.
ALTER TABLE bookings MODIFY status ENUM(
  'PENDING_PAYMENT', 'PENDING_APPROVAL', 'PENDING', 'CONFIRMED', 'REJECTED',
  'CHECKED_IN', 'IN_SERVICE', 'SERVICE_DONE', 'DISPUTED', 'COMPLETED', 'CANCELLED'
) NOT NULL DEFAULT 'PENDING_PAYMENT';

CREATE INDEX idx_bookings_provider_status_end ON bookings(provider_id, status, booking_end);
CREATE INDEX idx_bookings_status_created ON bookings(status, created_at);
CREATE INDEX idx_complaints_booking_status ON complaints(booking_id, status);
