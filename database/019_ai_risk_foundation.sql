-- AI risk foundation for MySQL 8. AI workers only use the HTTP API; they never receive DB credentials.
CREATE TABLE IF NOT EXISTS ai_scoring_outbox (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  aggregate_type ENUM('PAYMENT_DEPOSIT','WALLET_TRANSACTION','WITHDRAWAL_REQUEST','BOOKING') NOT NULL,
  aggregate_id BIGINT UNSIGNED NOT NULL,
  event_type VARCHAR(64) NOT NULL,
  occurred_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  payload_version SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  status ENUM('PENDING','LEASED','SCORED','FAILED') NOT NULL DEFAULT 'PENDING',
  lease_until TIMESTAMP NULL,
  attempt_count INT UNSIGNED NOT NULL DEFAULT 0,
  dedupe_key VARCHAR(160) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  processed_at TIMESTAMP NULL,
  last_error VARCHAR(500) NULL,
  UNIQUE KEY uk_ai_scoring_outbox_dedupe (dedupe_key),
  KEY ix_ai_scoring_outbox_lease (status, lease_until, created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ai_risk_scores (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  outbox_event_id BIGINT UNSIGNED NOT NULL,
  aggregate_type VARCHAR(32) NOT NULL,
  aggregate_id BIGINT UNSIGNED NOT NULL,
  model_name VARCHAR(100) NOT NULL,
  model_version VARCHAR(100) NOT NULL,
  risk_score DECIMAL(5,4) NOT NULL,
  risk_level ENUM('LOW','MEDIUM','HIGH') NOT NULL,
  explanation_summary VARCHAR(500) NULL,
  feature_snapshot JSON NOT NULL,
  scored_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  review_status ENUM('OPEN','REVIEWED','DISMISSED') NOT NULL DEFAULT 'OPEN',
  reviewer_profile_id BIGINT UNSIGNED NULL,
  reviewed_at TIMESTAMP NULL,
  reviewer_note VARCHAR(1000) NULL,
  UNIQUE KEY uk_ai_risk_scores_outbox (outbox_event_id),
  KEY ix_ai_risk_scores_review (risk_level, review_status, scored_at),
  CONSTRAINT fk_ai_risk_scores_outbox FOREIGN KEY (outbox_event_id) REFERENCES ai_scoring_outbox(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ai_operational_recommendations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  recommendation_type ENUM('INDEX','CAPACITY_FORECAST') NOT NULL,
  subject_name VARCHAR(255) NOT NULL,
  model_name VARCHAR(100) NOT NULL,
  model_version VARCHAR(100) NOT NULL,
  score DECIMAL(8,4) NULL,
  confidence DECIMAL(5,4) NULL,
  payload JSON NOT NULL,
  status ENUM('OPEN','REVIEWED','DISMISSED','APPROVED') NOT NULL DEFAULT 'OPEN',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewer_profile_id BIGINT UNSIGNED NULL,
  reviewed_at TIMESTAMP NULL,
  reviewer_note VARCHAR(1000) NULL,
  KEY ix_ai_operational_recommendations_status (status, created_at)
) ENGINE=InnoDB;
