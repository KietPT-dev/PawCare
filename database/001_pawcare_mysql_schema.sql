-- PawCare MySQL schema (MySQL 8.x)
-- Run with a MySQL administrator account in DBeaver.
-- This file is intentionally non-destructive: it does not DROP any table or database.

CREATE DATABASE IF NOT EXISTS pawcare
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE pawcare;

CREATE TABLE IF NOT EXISTS user_profiles (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  bonita_user_id BIGINT NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(30) NULL,
  email VARCHAR(254) NULL,
  address VARCHAR(500) NULL,
  role_code ENUM('CUSTOMER', 'PROVIDER', 'ADMIN') NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_profiles_bonita_user_id (bonita_user_id),
  KEY idx_user_profiles_role (role_code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS providers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  owner_profile_id BIGINT UNSIGNED NOT NULL,
  provider_type ENUM('INDIVIDUAL', 'SHOP') NOT NULL,
  name VARCHAR(200) NOT NULL,
  phone VARCHAR(30) NOT NULL,
  email VARCHAR(254) NULL,
  address VARCHAR(500) NOT NULL,
  service_area VARCHAR(500) NULL,
  description TEXT NULL,
  business_hours VARCHAR(500) NULL,
  status ENUM('PENDING', 'NEED_MORE_INFO', 'APPROVED', 'REJECTED', 'SUSPENDED') NOT NULL DEFAULT 'PENDING',
  rejection_reason TEXT NULL,
  average_rating DECIMAL(3,2) NOT NULL DEFAULT 0.00,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_providers_owner_profile (owner_profile_id),
  KEY idx_providers_status (status),
  CONSTRAINT fk_providers_owner_profile
    FOREIGN KEY (owner_profile_id) REFERENCES user_profiles(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS provider_documents (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  provider_id BIGINT UNSIGNED NOT NULL,
  document_type VARCHAR(80) NOT NULL,
  document_url VARCHAR(1000) NOT NULL,
  verification_status ENUM('PENDING', 'VALID', 'INVALID') NOT NULL DEFAULT 'PENDING',
  note TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_provider_documents_provider (provider_id),
  CONSTRAINT fk_provider_documents_provider
    FOREIGN KEY (provider_id) REFERENCES providers(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_profile_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  species VARCHAR(80) NOT NULL,
  breed VARCHAR(120) NULL,
  birth_date DATE NULL,
  gender ENUM('MALE', 'FEMALE', 'UNKNOWN') NOT NULL DEFAULT 'UNKNOWN',
  weight_kg DECIMAL(6,2) NULL,
  color VARCHAR(120) NULL,
  microchip_number VARCHAR(120) NULL,
  medical_notes TEXT NULL,
  photo_url VARCHAR(1000) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_pets_microchip (microchip_number),
  KEY idx_pets_customer (customer_profile_id),
  CONSTRAINT fk_pets_customer_profile
    FOREIGN KEY (customer_profile_id) REFERENCES user_profiles(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS service_categories (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  description TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_service_categories_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS services (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  provider_id BIGINT UNSIGNED NOT NULL,
  category_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(180) NOT NULL,
  description TEXT NULL,
  price DECIMAL(12,2) NOT NULL,
  duration_minutes INT UNSIGNED NOT NULL,
  pet_type_supported VARCHAR(250) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_services_provider_active (provider_id, is_active),
  KEY idx_services_category (category_id),
  CONSTRAINT fk_services_provider
    FOREIGN KEY (provider_id) REFERENCES providers(id),
  CONSTRAINT fk_services_category
    FOREIGN KEY (category_id) REFERENCES service_categories(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS staff (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  provider_id BIGINT UNSIGNED NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(30) NULL,
  email VARCHAR(254) NULL,
  skills TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_staff_provider_active (provider_id, is_active),
  CONSTRAINT fk_staff_provider
    FOREIGN KEY (provider_id) REFERENCES providers(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS staff_schedules (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  staff_id BIGINT UNSIGNED NOT NULL,
  start_at DATETIME NOT NULL,
  end_at DATETIME NOT NULL,
  status ENUM('AVAILABLE', 'BOOKED', 'BLOCKED') NOT NULL DEFAULT 'AVAILABLE',
  note VARCHAR(500) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_staff_schedules_lookup (staff_id, start_at, end_at, status),
  CONSTRAINT fk_staff_schedules_staff
    FOREIGN KEY (staff_id) REFERENCES staff(id),
  CONSTRAINT chk_staff_schedules_time CHECK (end_at > start_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS bookings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_profile_id BIGINT UNSIGNED NOT NULL,
  pet_id BIGINT UNSIGNED NOT NULL,
  provider_id BIGINT UNSIGNED NOT NULL,
  service_id BIGINT UNSIGNED NOT NULL,
  staff_id BIGINT UNSIGNED NULL,
  booking_start DATETIME NOT NULL,
  booking_end DATETIME NOT NULL,
  status ENUM('PENDING', 'CONFIRMED', 'REJECTED', 'CHECKED_IN', 'IN_SERVICE', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
  estimated_price DECIMAL(12,2) NOT NULL,
  customer_note TEXT NULL,
  provider_note TEXT NULL,
  cancel_reason TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_bookings_customer (customer_profile_id, booking_start),
  KEY idx_bookings_provider_status_time (provider_id, status, booking_start),
  KEY idx_bookings_staff_time (staff_id, booking_start),
  CONSTRAINT fk_bookings_customer_profile
    FOREIGN KEY (customer_profile_id) REFERENCES user_profiles(id),
  CONSTRAINT fk_bookings_pet
    FOREIGN KEY (pet_id) REFERENCES pets(id),
  CONSTRAINT fk_bookings_provider
    FOREIGN KEY (provider_id) REFERENCES providers(id),
  CONSTRAINT fk_bookings_service
    FOREIGN KEY (service_id) REFERENCES services(id),
  CONSTRAINT fk_bookings_staff
    FOREIGN KEY (staff_id) REFERENCES staff(id),
  CONSTRAINT chk_bookings_time CHECK (booking_end > booking_start)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS booking_status_history (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id BIGINT UNSIGNED NOT NULL,
  previous_status VARCHAR(30) NULL,
  new_status VARCHAR(30) NOT NULL,
  changed_by_profile_id BIGINT UNSIGNED NULL,
  note TEXT NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_booking_status_history_booking (booking_id, changed_at),
  CONSTRAINT fk_booking_status_history_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  CONSTRAINT fk_booking_status_history_profile
    FOREIGN KEY (changed_by_profile_id) REFERENCES user_profiles(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_method ENUM('MOCK_CASH', 'MOCK_CARD', 'MOCK_EWALLET') NOT NULL,
  status ENUM('PENDING', 'PAID', 'FAILED', 'REFUNDED') NOT NULL DEFAULT 'PENDING',
  paid_at DATETIME NULL,
  transaction_reference VARCHAR(120) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_payments_booking (booking_id),
  UNIQUE KEY uk_payments_transaction_reference (transaction_reference),
  CONSTRAINT fk_payments_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reviews (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id BIGINT UNSIGNED NOT NULL,
  customer_profile_id BIGINT UNSIGNED NOT NULL,
  provider_id BIGINT UNSIGNED NOT NULL,
  rating TINYINT UNSIGNED NOT NULL,
  comment TEXT NULL,
  is_visible TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_reviews_booking (booking_id),
  KEY idx_reviews_provider_visible (provider_id, is_visible),
  CONSTRAINT fk_reviews_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(id),
  CONSTRAINT fk_reviews_customer
    FOREIGN KEY (customer_profile_id) REFERENCES user_profiles(id),
  CONSTRAINT fk_reviews_provider
    FOREIGN KEY (provider_id) REFERENCES providers(id),
  CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  recipient_profile_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(250) NOT NULL,
  content TEXT NOT NULL,
  notification_type VARCHAR(80) NOT NULL,
  reference_type VARCHAR(80) NULL,
  reference_id BIGINT UNSIGNED NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  read_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_notifications_recipient_read (recipient_profile_id, is_read, created_at),
  CONSTRAINT fk_notifications_recipient
    FOREIGN KEY (recipient_profile_id) REFERENCES user_profiles(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS complaints (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id BIGINT UNSIGNED NOT NULL,
  customer_profile_id BIGINT UNSIGNED NOT NULL,
  provider_id BIGINT UNSIGNED NOT NULL,
  content TEXT NOT NULL,
  status ENUM('OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED') NOT NULL DEFAULT 'OPEN',
  admin_response TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_complaints_status_created (status, created_at),
  CONSTRAINT fk_complaints_booking
    FOREIGN KEY (booking_id) REFERENCES bookings(id),
  CONSTRAINT fk_complaints_customer
    FOREIGN KEY (customer_profile_id) REFERENCES user_profiles(id),
  CONSTRAINT fk_complaints_provider
    FOREIGN KEY (provider_id) REFERENCES providers(id)
) ENGINE=InnoDB;
