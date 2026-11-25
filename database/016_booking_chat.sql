-- Booking-scoped Customer/Provider chat v1. Apply once after 015.
CREATE TABLE IF NOT EXISTS conversations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id BIGINT UNSIGNED NOT NULL,
  customer_profile_id BIGINT UNSIGNED NOT NULL,
  provider_profile_id BIGINT UNSIGNED NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'OPEN',
  last_message_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_conversations_booking (booking_id),
  KEY idx_conversations_customer_recent (customer_profile_id,last_message_at),
  KEY idx_conversations_provider_recent (provider_profile_id,last_message_at),
  CONSTRAINT fk_conversations_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  CONSTRAINT fk_conversations_customer FOREIGN KEY (customer_profile_id) REFERENCES user_profiles(id),
  CONSTRAINT fk_conversations_provider FOREIGN KEY (provider_profile_id) REFERENCES user_profiles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS chat_messages (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  conversation_id BIGINT UNSIGNED NOT NULL,
  sender_profile_id BIGINT UNSIGNED NOT NULL,
  client_message_id VARCHAR(80) NOT NULL,
  content VARCHAR(2000) NOT NULL,
  sent_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  recalled_at DATETIME NULL,
  metadata_json JSON NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_chat_messages_idempotency (conversation_id,sender_profile_id,client_message_id),
  KEY idx_chat_messages_conversation_sent (conversation_id,sent_at,id),
  CONSTRAINT fk_chat_messages_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
  CONSTRAINT fk_chat_messages_sender FOREIGN KEY (sender_profile_id) REFERENCES user_profiles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS conversation_read_states (
  conversation_id BIGINT UNSIGNED NOT NULL,
  profile_id BIGINT UNSIGNED NOT NULL,
  last_read_message_id BIGINT UNSIGNED NULL,
  last_read_at DATETIME NULL,
  PRIMARY KEY (conversation_id,profile_id),
  KEY idx_conversation_read_states_profile (profile_id,last_read_at),
  CONSTRAINT fk_conversation_read_state_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
  CONSTRAINT fk_conversation_read_state_profile FOREIGN KEY (profile_id) REFERENCES user_profiles(id),
  CONSTRAINT fk_conversation_read_state_message FOREIGN KEY (last_read_message_id) REFERENCES chat_messages(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS conversation_reports (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  conversation_id BIGINT UNSIGNED NOT NULL,
  reporter_profile_id BIGINT UNSIGNED NOT NULL,
  category VARCHAR(64) NOT NULL,
  note VARCHAR(1000) NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'OPEN',
  reviewed_by_profile_id BIGINT UNSIGNED NULL,
  reviewed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_conversation_reports_status_created (status,created_at),
  KEY idx_conversation_reports_conversation (conversation_id),
  CONSTRAINT fk_conversation_reports_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
  CONSTRAINT fk_conversation_reports_reporter FOREIGN KEY (reporter_profile_id) REFERENCES user_profiles(id),
  CONSTRAINT fk_conversation_reports_reviewer FOREIGN KEY (reviewed_by_profile_id) REFERENCES user_profiles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
