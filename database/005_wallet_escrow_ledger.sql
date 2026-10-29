-- PawCare Wallet, VietQR deposit and Escrow Ledger.
-- Run ONCE in DBeaver after migrations 001 through 004.
-- This migration is intentionally append-only: wallet_transactions are the audit trail.
USE pawcare;

-- A booking must be funded before a provider can approve it.
ALTER TABLE bookings MODIFY status ENUM(
  'PENDING_PAYMENT', 'PENDING_APPROVAL', 'PENDING', 'CONFIRMED', 'REJECTED',
  'CHECKED_IN', 'IN_SERVICE', 'COMPLETED', 'CANCELLED'
) NOT NULL DEFAULT 'PENDING_PAYMENT';

CREATE TABLE wallets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  owner_type ENUM('USER', 'PROVIDER', 'PLATFORM_ADMIN') NOT NULL,
  -- USER = user_profiles.id; PROVIDER = providers.id; PLATFORM_ADMIN uses 0.
  owner_id BIGINT UNSIGNED NOT NULL,
  available_balance DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  locked_balance DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_wallet_owner (owner_type, owner_id),
  CONSTRAINT chk_wallet_balances_non_negative CHECK (available_balance >= 0 AND locked_balance >= 0)
) ENGINE=InnoDB;

CREATE TABLE wallet_transactions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  wallet_id BIGINT UNSIGNED NOT NULL,
  booking_id BIGINT UNSIGNED NULL,
  type ENUM('DEPOSIT', 'ESCROW_HOLD', 'ESCROW_RELEASE', 'COMMISSION_FEE', 'PROVIDER_PAYOUT', 'WITHDRAWAL') NOT NULL,
  -- Signed amount. balance_before/after refer to the balance bucket named in description.
  amount DECIMAL(14,2) NOT NULL,
  balance_before DECIMAL(14,2) NOT NULL,
  balance_after DECIMAL(14,2) NOT NULL,
  description VARCHAR(500) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_wallet_transactions_wallet_created (wallet_id, created_at),
  KEY idx_wallet_transactions_booking (booking_id, created_at),
  CONSTRAINT fk_wallet_transactions_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(id),
  CONSTRAINT fk_wallet_transactions_booking FOREIGN KEY (booking_id) REFERENCES bookings(id)
) ENGINE=InnoDB;

CREATE TABLE payment_deposits (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  booking_id BIGINT UNSIGNED NOT NULL,
  payment_code VARCHAR(80) NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  qr_url VARCHAR(1000) NULL,
  bank_tran_id VARCHAR(160) NULL,
  status ENUM('CREATED', 'PAID', 'ESCROW_HELD', 'EXPIRED', 'FAILED') NOT NULL DEFAULT 'CREATED',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_payment_deposits_code (payment_code),
  UNIQUE KEY uk_payment_deposits_bank_tran (bank_tran_id),
  UNIQUE KEY uk_payment_deposits_booking (booking_id),
  KEY idx_payment_deposits_user_status (user_id, status),
  CONSTRAINT fk_payment_deposits_user FOREIGN KEY (user_id) REFERENCES user_profiles(id),
  CONSTRAINT fk_payment_deposits_booking FOREIGN KEY (booking_id) REFERENCES bookings(id),
  CONSTRAINT chk_payment_deposits_amount CHECK (amount > 0)
) ENGINE=InnoDB;

CREATE TABLE withdrawal_requests (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  wallet_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  bank_name VARCHAR(180) NOT NULL,
  bank_account_no VARCHAR(80) NOT NULL,
  bank_account_name VARCHAR(180) NOT NULL,
  bonita_case_id BIGINT NULL,
  status ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
  admin_note VARCHAR(500) NULL,
  reviewed_by_profile_id BIGINT UNSIGNED NULL,
  reviewed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_withdrawal_requests_wallet_status (wallet_id, status),
  KEY idx_withdrawal_requests_status_created (status, created_at),
  CONSTRAINT fk_withdrawal_requests_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(id),
  CONSTRAINT fk_withdrawal_requests_reviewer FOREIGN KEY (reviewed_by_profile_id) REFERENCES user_profiles(id),
  CONSTRAINT chk_withdrawal_requests_amount CHECK (amount > 0)
) ENGINE=InnoDB;
