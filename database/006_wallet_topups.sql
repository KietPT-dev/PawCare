-- Standalone VietQR top-ups are not associated with a booking.
ALTER TABLE payment_deposits MODIFY booking_id BIGINT UNSIGNED NULL;
