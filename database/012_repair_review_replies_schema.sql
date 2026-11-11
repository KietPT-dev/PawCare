-- PawCare review reply schema repair.
-- Run ONCE only when 011 reports an object that already exists, or after an
-- interrupted/manual schema update. It safely adds only missing objects.
-- Compatible with MySQL 8.0 releases that do not support every ALTER ... IF
-- NOT EXISTS variant.

DROP PROCEDURE IF EXISTS pawcare_ensure_review_reply_schema;

DELIMITER //
CREATE PROCEDURE pawcare_ensure_review_reply_schema()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'reviews' AND column_name = 'provider_reply'
    ) THEN
        ALTER TABLE reviews ADD COLUMN provider_reply TEXT NULL AFTER comment;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'reviews' AND column_name = 'provider_replied_at'
    ) THEN
        ALTER TABLE reviews ADD COLUMN provider_replied_at DATETIME NULL AFTER provider_reply;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'reviews' AND column_name = 'provider_replied_by_profile_id'
    ) THEN
        ALTER TABLE reviews
            ADD COLUMN provider_replied_by_profile_id BIGINT UNSIGNED NULL AFTER provider_replied_at;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.statistics
        WHERE table_schema = DATABASE() AND table_name = 'reviews' AND index_name = 'idx_reviews_provider_reply'
    ) THEN
        ALTER TABLE reviews ADD KEY idx_reviews_provider_reply (provider_id, provider_replied_at);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.referential_constraints
        WHERE constraint_schema = DATABASE()
          AND table_name = 'reviews'
          AND constraint_name = 'fk_reviews_provider_replied_by'
    ) THEN
        ALTER TABLE reviews
            ADD CONSTRAINT fk_reviews_provider_replied_by
                FOREIGN KEY (provider_replied_by_profile_id) REFERENCES user_profiles(id);
    END IF;
END //
DELIMITER ;

CALL pawcare_ensure_review_reply_schema();
DROP PROCEDURE pawcare_ensure_review_reply_schema;

-- Verification: all five values below must be 1 after the repair.
SELECT
    (SELECT COUNT(*) FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'reviews' AND column_name = 'provider_reply') AS has_provider_reply,
    (SELECT COUNT(*) FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'reviews' AND column_name = 'provider_replied_at') AS has_provider_replied_at,
    (SELECT COUNT(*) FROM information_schema.columns
      WHERE table_schema = DATABASE() AND table_name = 'reviews' AND column_name = 'provider_replied_by_profile_id') AS has_provider_replied_by,
    (SELECT COUNT(*) FROM information_schema.statistics
      WHERE table_schema = DATABASE() AND table_name = 'reviews' AND index_name = 'idx_reviews_provider_reply') AS has_reply_index,
    (SELECT COUNT(*) FROM information_schema.referential_constraints
      WHERE constraint_schema = DATABASE() AND table_name = 'reviews'
        AND constraint_name = 'fk_reviews_provider_replied_by') AS has_reply_foreign_key;
