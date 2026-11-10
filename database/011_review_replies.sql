-- Apply ONCE after 010. Provider replies are attached to the original review
-- so ownership remains verifiable through reviews.provider_id.
ALTER TABLE reviews
    ADD COLUMN provider_reply TEXT NULL AFTER comment,
    ADD COLUMN provider_replied_at DATETIME NULL AFTER provider_reply,
    ADD COLUMN provider_replied_by_profile_id BIGINT UNSIGNED NULL AFTER provider_replied_at,
    ADD KEY idx_reviews_provider_reply (provider_id, provider_replied_at),
    ADD CONSTRAINT fk_reviews_provider_replied_by
        FOREIGN KEY (provider_replied_by_profile_id) REFERENCES user_profiles(id);
