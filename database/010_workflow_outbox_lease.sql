-- Apply ONCE after 009. A short lease prevents two API instances from
-- delivering the same Bonita outbox event concurrently.
ALTER TABLE booking_workflow_outbox
    ADD COLUMN locked_at DATETIME NULL AFTER processed_at,
    ADD KEY idx_booking_workflow_outbox_lease (status, locked_at);
