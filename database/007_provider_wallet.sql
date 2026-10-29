-- Provider wallet and escrow accounting for the Provider portal.
ALTER TABLE bookings
  ADD COLUMN escrow_status ENUM('HELD','REFUNDED','SETTLED') NULL AFTER estimated_price;

CREATE TABLE IF NOT EXISTS provider_wallets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  provider_id BIGINT UNSIGNED NOT NULL,
  available_balance DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_earned DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_provider_wallets_provider (provider_id),
  CONSTRAINT fk_provider_wallets_provider FOREIGN KEY (provider_id) REFERENCES providers(id),
  CONSTRAINT chk_provider_wallet_balances CHECK (available_balance >= 0 AND total_earned >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS provider_wallet_transactions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  wallet_id BIGINT UNSIGNED NOT NULL,
  booking_id BIGINT UNSIGNED NOT NULL,
  gross_amount DECIMAL(12,2) NOT NULL,
  platform_fee DECIMAL(12,2) NOT NULL,
  net_amount DECIMAL(12,2) NOT NULL,
  type ENUM('BOOKING_PAYOUT','WITHDRAWAL_HOLD','WITHDRAWAL_RETURN','WITHDRAWAL_PAID') NOT NULL,
  description VARCHAR(500) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_provider_wallet_payout_booking (booking_id, type),
  KEY idx_provider_wallet_transactions_wallet_created (wallet_id, created_at),
  CONSTRAINT fk_provider_wallet_transactions_wallet FOREIGN KEY (wallet_id) REFERENCES provider_wallets(id),
  CONSTRAINT fk_provider_wallet_transactions_booking FOREIGN KEY (booking_id) REFERENCES bookings(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS provider_withdrawal_requests (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  wallet_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  bank_name VARCHAR(150) NOT NULL,
  bank_account_no VARCHAR(80) NOT NULL,
  bank_account_name VARCHAR(150) NOT NULL,
  status ENUM('PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
  admin_note VARCHAR(500) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_provider_withdrawals_wallet_status (wallet_id, status),
  CONSTRAINT fk_provider_withdrawals_wallet FOREIGN KEY (wallet_id) REFERENCES provider_wallets(id),
  CONSTRAINT chk_provider_withdrawal_amount CHECK (amount > 0)
) ENGINE=InnoDB;
