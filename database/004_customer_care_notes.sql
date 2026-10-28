-- PawCare customer care notes.
-- Run ONCE in DBeaver after 001, 002 and 003.
USE pawcare;

CREATE TABLE IF NOT EXISTS care_notes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_profile_id BIGINT UNSIGNED NOT NULL,
  pet_id BIGINT UNSIGNED NULL,
  title VARCHAR(180) NOT NULL,
  content TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_care_notes_customer_created (customer_profile_id, created_at),
  KEY idx_care_notes_pet (pet_id),
  CONSTRAINT fk_care_notes_customer
    FOREIGN KEY (customer_profile_id) REFERENCES user_profiles(id) ON DELETE CASCADE,
  CONSTRAINT fk_care_notes_pet
    FOREIGN KEY (pet_id) REFERENCES pets(id) ON DELETE SET NULL
) ENGINE=InnoDB;
