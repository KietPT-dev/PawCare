-- Bonita BookingService orchestration bridge.
-- Run ONCE in DBeaver after migration 007.
-- MySQL remains PawCare's financial source of truth.  This table is an
-- outbox: workflow calls are retried without ever rolling back an escrow
-- transaction that was already committed successfully.
USE pawcare;

ALTER TABLE bookings
  ADD COLUMN bonita_case_id BIGINT NULL AFTER cancel_reason,
  ADD COLUMN bonita_process_definition_id BIGINT NULL AFTER bonita_case_id;

CREATE INDEX idx_bookings_bonita_case ON bookings (bonita_case_id);

CREATE TABLE booking_workflow_outbox (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id BIGINT UNSIGNED NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  payload_json JSON NULL,
  status ENUM('PENDING', 'SENT', 'FAILED') NOT NULL DEFAULT 'PENDING',
  attempts INT UNSIGNED NOT NULL DEFAULT 0,
  last_error VARCHAR(1000) NULL,
  processed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_booking_workflow_event (booking_id, event_type),
  KEY idx_booking_workflow_outbox_pending (status, updated_at),
  CONSTRAINT fk_booking_workflow_outbox_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
) ENGINE=InnoDB;
