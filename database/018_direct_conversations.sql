-- Direct Customer-to-Provider conversations. Apply once after 017.
-- Existing booking conversations remain unchanged and are backfilled as BOOKING.
DROP PROCEDURE IF EXISTS pawcare_enable_direct_conversations;
DELIMITER //
CREATE PROCEDURE pawcare_enable_direct_conversations()
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='conversations' AND column_name='conversation_type'
  ) THEN
    ALTER TABLE conversations
      ADD COLUMN conversation_type VARCHAR(16) NULL AFTER booking_id;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='conversations' AND column_name='direct_conversation_key'
  ) THEN
    ALTER TABLE conversations
      ADD COLUMN direct_conversation_key VARCHAR(80) NULL AFTER conversation_type;
  END IF;

  -- A nullable FK still protects booking conversations while allowing DIRECT.
  ALTER TABLE conversations MODIFY booking_id BIGINT UNSIGNED NULL;
  UPDATE conversations
    SET conversation_type='BOOKING'
    WHERE conversation_type IS NULL OR conversation_type='';
  ALTER TABLE conversations
    MODIFY conversation_type VARCHAR(16) NOT NULL DEFAULT 'BOOKING';

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.statistics
    WHERE table_schema=DATABASE() AND table_name='conversations'
      AND index_name='uk_conversations_direct_key'
  ) THEN
    CREATE UNIQUE INDEX uk_conversations_direct_key
      ON conversations(direct_conversation_key);
  END IF;
END //
DELIMITER ;
CALL pawcare_enable_direct_conversations();
DROP PROCEDURE pawcare_enable_direct_conversations;
