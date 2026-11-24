-- Provider/customer location and Provider cover image. Apply once after 014.
-- This migration is safe to re-run on MySQL 8 releases that lack
-- ALTER TABLE ... ADD COLUMN IF NOT EXISTS.
DROP PROCEDURE IF EXISTS pawcare_ensure_location_and_cover;
DELIMITER //
CREATE PROCEDURE pawcare_ensure_location_and_cover()
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='user_profiles' AND column_name='address_line1') THEN
    ALTER TABLE user_profiles ADD COLUMN address_line1 VARCHAR(255) NULL AFTER address;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='user_profiles' AND column_name='ward') THEN
    ALTER TABLE user_profiles ADD COLUMN ward VARCHAR(150) NULL AFTER address_line1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='user_profiles' AND column_name='district') THEN
    ALTER TABLE user_profiles ADD COLUMN district VARCHAR(150) NULL AFTER ward;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='user_profiles' AND column_name='province') THEN
    ALTER TABLE user_profiles ADD COLUMN province VARCHAR(150) NULL AFTER district;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='user_profiles' AND column_name='latitude') THEN
    ALTER TABLE user_profiles ADD COLUMN latitude DECIMAL(10,7) NULL AFTER province;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='user_profiles' AND column_name='longitude') THEN
    ALTER TABLE user_profiles ADD COLUMN longitude DECIMAL(10,7) NULL AFTER latitude;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='user_profiles' AND column_name='geocode_status') THEN
    ALTER TABLE user_profiles ADD COLUMN geocode_status VARCHAR(32) NOT NULL DEFAULT 'NOT_REQUESTED' AFTER longitude;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='user_profiles' AND column_name='geocode_error') THEN
    ALTER TABLE user_profiles ADD COLUMN geocode_error VARCHAR(500) NULL AFTER geocode_status;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='user_profiles' AND column_name='geocoded_at') THEN
    ALTER TABLE user_profiles ADD COLUMN geocoded_at DATETIME NULL AFTER geocode_error;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='address_line1') THEN
    ALTER TABLE providers ADD COLUMN address_line1 VARCHAR(255) NULL AFTER address;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='ward') THEN
    ALTER TABLE providers ADD COLUMN ward VARCHAR(150) NULL AFTER address_line1;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='district') THEN
    ALTER TABLE providers ADD COLUMN district VARCHAR(150) NULL AFTER ward;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='province') THEN
    ALTER TABLE providers ADD COLUMN province VARCHAR(150) NULL AFTER district;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='latitude') THEN
    ALTER TABLE providers ADD COLUMN latitude DECIMAL(10,7) NULL AFTER province;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='longitude') THEN
    ALTER TABLE providers ADD COLUMN longitude DECIMAL(10,7) NULL AFTER latitude;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='geocode_status') THEN
    ALTER TABLE providers ADD COLUMN geocode_status VARCHAR(32) NOT NULL DEFAULT 'NOT_REQUESTED' AFTER longitude;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='geocode_error') THEN
    ALTER TABLE providers ADD COLUMN geocode_error VARCHAR(500) NULL AFTER geocode_status;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='geocoded_at') THEN
    ALTER TABLE providers ADD COLUMN geocoded_at DATETIME NULL AFTER geocode_error;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='providers' AND column_name='cover_image_url') THEN
    ALTER TABLE providers ADD COLUMN cover_image_url VARCHAR(1000) NULL AFTER description;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='providers' AND index_name='idx_providers_discovery_location') THEN
    CREATE INDEX idx_providers_discovery_location ON providers(status, is_active, latitude, longitude);
  END IF;
END //
DELIMITER ;
CALL pawcare_ensure_location_and_cover();
DROP PROCEDURE pawcare_ensure_location_and_cover;
