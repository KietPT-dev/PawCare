-- PawCare development seed data.
-- Run this only after 001_pawcare_mysql_schema.sql.

USE pawcare;

INSERT INTO user_profiles (bonita_user_id, full_name, phone, email, role_code)
VALUES
  (10001, 'Customer Demo', '0900000001', 'customer.demo@pawcare.local', 'CUSTOMER'),
  (10002, 'Provider Demo', '0900000002', 'provider.demo@pawcare.local', 'PROVIDER'),
  (10003, 'Admin Demo', '0900000003', 'admin.demo@pawcare.local', 'ADMIN')
ON DUPLICATE KEY UPDATE full_name = VALUES(full_name);

INSERT INTO service_categories (name, description)
VALUES
  ('Grooming', 'Tắm, sấy và chăm sóc lông'),
  ('Pet Sitting', 'Trông giữ thú cưng'),
  ('Nail Care', 'Cắt và chăm sóc móng')
ON DUPLICATE KEY UPDATE description = VALUES(description);

INSERT INTO providers
  (owner_profile_id, provider_type, name, phone, email, address, service_area, description, business_hours, status)
SELECT id, 'SHOP', 'PawCare Demo Pet Shop', '0900000002', 'provider.demo@pawcare.local',
       'Quận 1, TP. Hồ Chí Minh', 'Quận 1, Quận 3, Bình Thạnh',
       'Cơ sở demo phục vụ kiểm thử PawCare.', '08:00-20:00', 'APPROVED'
FROM user_profiles
WHERE bonita_user_id = 10002
ON DUPLICATE KEY UPDATE name = VALUES(name), status = VALUES(status);

INSERT INTO pets
  (customer_profile_id, name, species, breed, birth_date, gender, weight_kg, color, medical_notes)
SELECT id, 'Gấu', 'DOG', 'Aidi', '2024-02-01', 'FEMALE', 12.50, 'Nâu', 'Không có lưu ý đặc biệt'
FROM user_profiles
WHERE bonita_user_id = 10001
ON DUPLICATE KEY UPDATE name = VALUES(name), medical_notes = VALUES(medical_notes);

INSERT INTO services
  (provider_id, category_id, name, description, price, duration_minutes, pet_type_supported)
SELECT p.id, c.id, 'Tắm và sấy cơ bản', 'Tắm, sấy và vệ sinh cơ bản', 150000, 60, 'DOG,CAT'
FROM providers p
JOIN service_categories c ON c.name = 'Grooming'
WHERE p.name = 'PawCare Demo Pet Shop'
ON DUPLICATE KEY UPDATE price = VALUES(price), duration_minutes = VALUES(duration_minutes);

INSERT INTO staff (provider_id, full_name, phone, email, skills)
SELECT id, 'Nguyễn Demo', '0900000004', 'staff.demo@pawcare.local', 'Grooming;Bathing;Nail Care'
FROM providers
WHERE name = 'PawCare Demo Pet Shop'
ON DUPLICATE KEY UPDATE skills = VALUES(skills);
