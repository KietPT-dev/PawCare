-- Chat report moderation fields. Apply once after 016_booking_chat.sql.
-- Uses a temporary procedure for compatibility with MySQL 8 variants that do
-- not support ALTER TABLE ... ADD COLUMN IF NOT EXISTS.
DROP PROCEDURE IF EXISTS pawcare_ensure_chat_report_moderation;
DELIMITER //
CREATE PROCEDURE pawcare_ensure_chat_report_moderation()
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema=DATABASE() AND table_name='conversation_reports'
      AND column_name='reviewer_note'
  ) THEN
    ALTER TABLE conversation_reports
      ADD COLUMN reviewer_note VARCHAR(1000) NULL AFTER reviewed_at;
  END IF;
END //
DELIMITER ;
CALL pawcare_ensure_chat_report_moderation();
DROP PROCEDURE pawcare_ensure_chat_report_moderation;
