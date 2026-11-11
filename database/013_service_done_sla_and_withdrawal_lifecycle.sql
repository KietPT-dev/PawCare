-- PawCare booking SLA and withdrawal lifecycle.
-- Apply ONCE after 012.  This migration is append-only; do not edit prior migrations.
USE pawcare;

-- SERVICE_DONE remains escrow-held.  At its confirmation deadline it moves to
-- SYSTEM_REVIEW, never automatically to COMPLETED or a provider payout.
ALTER TABLE bookings MODIFY status ENUM(
  'PENDING_PAYMENT','PENDING_APPROVAL','PENDING','CONFIRMED','REJECTED',
  'CHECKED_IN','IN_SERVICE','SERVICE_DONE','COMPLETED','DISPUTED',
  'CANCELLED','EXPIRED','SYSTEM_REVIEW'
) NOT NULL DEFAULT 'PENDING_PAYMENT';
ALTER TABLE bookings
  ADD COLUMN service_done_at DATETIME NULL AFTER provider_note,
  ADD COLUMN customer_confirmation_due_at DATETIME NULL AFTER service_done_at,
  ADD COLUMN service_done_reminder_at DATETIME NULL AFTER customer_confirmation_due_at,
  ADD KEY idx_bookings_service_done_deadline (status, customer_confirmation_due_at);

-- Approval reserves money only.  An external bank integration is deliberately
-- not simulated: PAID must be set only after manual/real reconciliation.
ALTER TABLE withdrawal_requests MODIFY status ENUM(
  'PENDING','APPROVED','REJECTED','PROCESSING','PAID','FAILED'
) NOT NULL DEFAULT 'PENDING';
ALTER TABLE withdrawal_requests
  ADD COLUMN payout_reference VARCHAR(160) NULL AFTER bonita_case_id,
  ADD COLUMN processing_at DATETIME NULL AFTER reviewed_at,
  ADD COLUMN paid_at DATETIME NULL AFTER processing_at,
  ADD COLUMN failed_at DATETIME NULL AFTER paid_at,
  ADD KEY idx_withdrawal_requests_status_updated (status, updated_at);
