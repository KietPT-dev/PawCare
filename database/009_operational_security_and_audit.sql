-- PawCare operational hardening. Apply ONCE after 008.
-- Existing databases stay untouched until this migration is explicitly run.

ALTER TABLE notifications
    ADD COLUMN dedupe_key VARCHAR(128) NULL AFTER reference_id;

ALTER TABLE notifications
    ADD UNIQUE KEY uk_notifications_recipient_dedupe (recipient_profile_id, dedupe_key);

CREATE TABLE IF NOT EXISTS auth_action_tokens (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    profile_id BIGINT UNSIGNED NOT NULL,
    purpose VARCHAR(32) NOT NULL,
    token_hash CHAR(64) NOT NULL,
    expires_at DATETIME NOT NULL,
    used_at DATETIME NULL,
    revoked_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_auth_action_tokens_hash (token_hash),
    KEY idx_auth_action_tokens_profile_purpose (profile_id, purpose, expires_at),
    CONSTRAINT fk_auth_action_tokens_profile FOREIGN KEY (profile_id) REFERENCES user_profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS auth_rate_limits (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    action_type VARCHAR(32) NOT NULL,
    subject_hash CHAR(64) NOT NULL,
    window_started_at DATETIME NOT NULL,
    attempt_count INT NOT NULL DEFAULT 0,
    blocked_until DATETIME NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_auth_rate_limits_action_subject (action_type, subject_hash),
    KEY idx_auth_rate_limits_blocked_until (blocked_until)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    actor_profile_id BIGINT UNSIGNED NULL,
    action_type VARCHAR(64) NOT NULL,
    entity_type VARCHAR(64) NOT NULL,
    entity_id BIGINT UNSIGNED NULL,
    details_json JSON NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_audit_logs_entity (entity_type, entity_id, created_at),
    KEY idx_audit_logs_actor (actor_profile_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 005 already has a unique bank transaction reference.  Keep it as the
-- idempotency boundary for SePay callbacks; do not remove or recreate it.
