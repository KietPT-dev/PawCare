-- Additive follow-up to 019.  The worker receives only this curated feature snapshot,
-- never a business payload or direct database access.
ALTER TABLE ai_scoring_outbox
  ADD COLUMN feature_snapshot JSON NULL AFTER payload_version;
