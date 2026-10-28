-- PawCare public identity and VNPAY Sandbox upgrade.
-- Run ONCE in DBeaver after 001 and 002. Compatible with older MySQL 8.x releases.
USE pawcare;

-- Customer/Provider accounts belong to PawCare. Bonita mapping is optional.
ALTER TABLE user_profiles MODIFY bonita_user_id BIGINT NULL;
ALTER TABLE user_profiles ADD COLUMN password_hash VARCHAR(255) NULL AFTER role_code;
ALTER TABLE user_profiles ADD COLUMN email_verified TINYINT(1) NOT NULL DEFAULT 0 AFTER password_hash;
ALTER TABLE user_profiles ADD COLUMN password_updated_at DATETIME NULL AFTER email_verified;
ALTER TABLE user_profiles ADD COLUMN last_login_at DATETIME NULL AFTER password_updated_at;
CREATE UNIQUE INDEX uk_user_profiles_email ON user_profiles (email);

CREATE TABLE refresh_tokens (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  profile_id BIGINT UNSIGNED NOT NULL,
  token_hash VARCHAR(128) NOT NULL,
  expires_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_refresh_tokens_hash (token_hash),
  KEY idx_refresh_tokens_profile_expiry (profile_id, expires_at),
  CONSTRAINT fk_refresh_tokens_profile
    FOREIGN KEY (profile_id) REFERENCES user_profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- VNPAY is a real Sandbox gateway; legacy MOCK_* values remain usable in tests.
ALTER TABLE payments MODIFY payment_method ENUM('MOCK_CASH', 'MOCK_CARD', 'MOCK_EWALLET', 'VNPAY') NOT NULL;
ALTER TABLE payments ADD COLUMN gateway VARCHAR(40) NULL AFTER payment_method;
ALTER TABLE payments ADD COLUMN gateway_transaction_ref VARCHAR(120) NULL AFTER transaction_reference;
ALTER TABLE payments ADD COLUMN gateway_transaction_no VARCHAR(120) NULL AFTER gateway_transaction_ref;
ALTER TABLE payments ADD COLUMN gateway_response_code VARCHAR(20) NULL AFTER gateway_transaction_no;
ALTER TABLE payments ADD COLUMN raw_callback_payload TEXT NULL AFTER gateway_response_code;
ALTER TABLE payments ADD COLUMN callback_received_at DATETIME NULL AFTER raw_callback_payload;
CREATE UNIQUE INDEX uk_payments_gateway_transaction_ref ON payments (gateway, gateway_transaction_ref);
