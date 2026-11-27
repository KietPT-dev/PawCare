-- Apply once after 020.
-- BookingWorkflowOutbox claims an event with a short PROCESSING lease before
-- calling Bonita. Migration 008 predated that lease and its ENUM omitted the
-- transient value, causing the scheduler to fail before it could deliver.
ALTER TABLE booking_workflow_outbox
  MODIFY status ENUM('PENDING', 'PROCESSING', 'SENT', 'FAILED')
    NOT NULL DEFAULT 'PENDING';
