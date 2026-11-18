-- ProviderApproval 1.1 bridge. Apply once after 013.
CREATE TABLE IF NOT EXISTS provider_approval_workflow_outbox (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  provider_id BIGINT UNSIGNED NOT NULL,
  event_type VARCHAR(64) NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'PENDING',
  attempts INT NOT NULL DEFAULT 0,
  locked_at DATETIME NULL,
  last_error VARCHAR(1000) NULL,
  processed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_provider_approval_workflow_event (provider_id,event_type),
  KEY idx_provider_approval_workflow_pending (status,created_at),
  CONSTRAINT fk_provider_approval_workflow_provider FOREIGN KEY (provider_id) REFERENCES providers(id) ON DELETE CASCADE
);

-- Older MySQL 8 builds do not support ADD COLUMN IF NOT EXISTS.
DROP PROCEDURE IF EXISTS pawcare_ensure_provider_approval_bridge;
DELIMITER //
CREATE PROCEDURE pawcare_ensure_provider_approval_bridge()
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='bonita_case_id') THEN
    ALTER TABLE providers ADD COLUMN bonita_case_id BIGINT NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='bonita_process_definition_id') THEN
    ALTER TABLE providers ADD COLUMN bonita_process_definition_id BIGINT NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='approval_review_note') THEN
    ALTER TABLE providers ADD COLUMN approval_review_note TEXT NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='approval_decided_at') THEN
    ALTER TABLE providers ADD COLUMN approval_decided_at DATETIME NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='providers' AND index_name='idx_providers_bonita_case') THEN
    CREATE INDEX idx_providers_bonita_case ON providers(bonita_case_id);
  END IF;
END //
DELIMITER ;
CALL pawcare_ensure_provider_approval_bridge();
DROP PROCEDURE pawcare_ensure_provider_approval_bridge;
