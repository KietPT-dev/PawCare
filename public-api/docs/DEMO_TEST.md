# PawCare — Quy trình kiểm tra demo toàn bộ Public API

Tài liệu này kiểm tra phần còn thiếu sau MT4–MT6: Public API, tài khoản Customer/Provider, booking, lịch trống, gợi ý và VNPAY Sandbox.

## 1. Chuẩn bị một lần

Trong Terminal, mở thư mục Public API:

```zsh
cd /Applications/BonitaStudioCommunity-2025.2-u0.app/Contents/Eclipse/workspace/PawCare/public-api
```

Thiết lập biến môi trường. Thay `YOUR_MYSQL_PASSWORD` bằng mật khẩu kết nối MySQL của bạn. Nếu tài khoản đang dùng là `root` thì để `PAWCARE_DB_USERNAME=root`.

```zsh
export PAWCARE_DB_URL='jdbc:mysql://localhost:3306/pawcare?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Ho_Chi_Minh'
export PAWCARE_DB_USERNAME='root'
export PAWCARE_DB_PASSWORD='YOUR_MYSQL_PASSWORD'
export PAWCARE_JWT_SECRET="$(openssl rand -base64 48)"
export PAWCARE_JWT_ISSUER='pawcare-public-api'
export VNPAY_ENABLED='false'
```

`PAWCARE_JWT_SECRET` phải giữ nguyên trong lúc server đang chạy. Khi tắt Terminal hoặc đổi secret, các access token cũ hết hiệu lực.

## 2. Chạy Public API

Mở Terminal thứ nhất, vẫn ở thư mục `public-api`:

```zsh
mvn spring-boot:run
```

Khi thấy `Started PawCarePublicApiApplication`, API sẵn sàng ở `http://localhost:8081`.

Mở Terminal thứ hai và chạy test tự động cơ bản:

```zsh
cd /Applications/BonitaStudioCommunity-2025.2-u0.app/Contents/Eclipse/workspace/PawCare/public-api
chmod +x scripts/test-public-api.sh
./scripts/test-public-api.sh
```

Script đăng ký một Customer demo mới, đăng nhập, tạo pet, gọi catalog và API gợi ý. Nó in `PASS` cho mỗi bước thành công. Lưu các ID mà script in ra để test booking.

## 3. Chuẩn bị dữ liệu Provider để test booking và MT6

Provider tự đăng ký từ Public API sẽ ở trạng thái `PENDING`, đúng nghiệp vụ. Để demo phần đặt lịch, dùng Provider đã được Bonita duyệt hoặc tạo dữ liệu demo bằng DBeaver.

Chạy truy vấn chỉ đọc này trong database `pawcare` để chọn dữ liệu hợp lệ:

```sql
SELECT s.id AS service_id, s.name AS service_name, s.provider_id,
       st.id AS staff_id, st.full_name
FROM services s
JOIN providers p ON p.id = s.provider_id
LEFT JOIN staff st ON st.provider_id = p.id AND st.is_active = 1
WHERE s.is_active = 1
  AND p.is_active = 1
  AND p.status = 'APPROVED'
ORDER BY s.id, st.id;
```

Nếu chưa có Provider được duyệt, hãy đăng ký Provider qua `POST /api/v1/auth/register` với `"role":"PROVIDER"`, rồi dùng quy trình Bonita `ProviderApproval` để Admin duyệt. Sau đó Provider đăng nhập, tạo Service, Staff và Schedule bằng các endpoint Provider. Đây là một phần demo nghiệp vụ, không phải thay đổi cấu hình hệ thống.

Tạo schedule `AVAILABLE` cho staff tại thời gian sẽ đặt, ví dụ:

```http
POST /api/v1/provider/schedules
Authorization: Bearer <provider_access_token>
Content-Type: application/json

{
  "staffId": 1,
  "startAt": "2026-10-20T08:00:00",
  "endAt": "2026-10-20T18:00:00",
  "status": "AVAILABLE",
  "note": "Lịch demo"
}
```

## 4. Test luồng Customer → Booking → MT6

Thay các placeholder bằng access token và ID thật:

```zsh
export CUSTOMER_TOKEN='access-token-customer'
export PET_ID=1
export PROVIDER_ID=1
export SERVICE_ID=1
export STAFF_ID=1
```

Kiểm tra lịch trống (không cần đăng nhập):

```zsh
curl -sS "http://localhost:8081/api/v1/availability/providers/$PROVIDER_ID?serviceId=$SERVICE_ID&bookingStart=2026-10-20T09:00:00"
```

Kết quả cần có `"available":true` và `availableStaff` chứa Staff của Provider.

Gợi ý Provider/Service (Customer đã đăng nhập):

```zsh
curl -sS "http://localhost:8081/api/v1/recommendations?petId=$PET_ID&bookingStart=2026-10-20T09:00:00" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN"
```

Tạo booking:

```zsh
curl -sS -X POST http://localhost:8081/api/v1/bookings \
  -H "Authorization: Bearer $CUSTOMER_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"petId\":$PET_ID,\"providerId\":$PROVIDER_ID,\"serviceId\":$SERVICE_ID,\"staffId\":$STAFF_ID,\"bookingStart\":\"2026-10-20T09:00:00\",\"customerNote\":\"Booking demo\"}"
```

Sau đó gọi lại API lịch trống cùng khung giờ. Staff vừa đặt phải không còn trong `availableStaff`. Đây là bằng chứng phần chống trùng lịch hoạt động.

Đăng nhập bằng Provider, lấy `PROVIDER_TOKEN`, rồi đổi trạng thái booking theo chuỗi:

```text
PENDING → CONFIRMED → CHECKED_IN → IN_SERVICE → COMPLETED
```

Mỗi lần gọi:

```zsh
curl -sS -X PUT "http://localhost:8081/api/v1/bookings/<BOOKING_ID>/status" \
  -H "Authorization: Bearer $PROVIDER_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"status":"CONFIRMED","note":"Provider xác nhận"}'
```

Thay `CONFIRMED` lần lượt bằng các trạng thái tiếp theo. Sau `COMPLETED`, Customer có thể tạo review qua `POST /api/v1/reviews`.

## 5. Test VNPAY Sandbox — thực hiện sau cùng

Phần này cần thao tác từ bạn vì cần đăng ký/lấy thông tin Sandbox:

1. Lấy `VNPAY_TMN_CODE` và `VNPAY_HASH_SECRET` trên VNPAY Sandbox.
2. Tạo HTTPS public tunnel trỏ về cổng `8081`; `localhost` không nhận IPN từ VNPAY.
3. Khai báo URL callback:
   - Return: `https://<public-domain>/api/v1/payments/vnpay/return`
   - IPN: `https://<public-domain>/api/v1/payments/vnpay/ipn`
4. Khởi động lại Public API với các biến môi trường:

```zsh
export VNPAY_ENABLED=true
export VNPAY_TMN_CODE='...'
export VNPAY_HASH_SECRET='...'
export VNPAY_RETURN_URL='https://<public-domain>/api/v1/payments/vnpay/return'
export VNPAY_IPN_URL='https://<public-domain>/api/v1/payments/vnpay/ipn'
mvn spring-boot:run
```

5. Dùng Customer token tạo URL thanh toán cho booking `PENDING` hoặc `CONFIRMED`:

```zsh
curl -sS -X POST http://localhost:8081/api/v1/payments/vnpay/create \
  -H "Authorization: Bearer $CUSTOMER_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"bookingId":<BOOKING_ID>}'
```

Mở `paymentUrl` trả về, thanh toán bằng thẻ Sandbox. Sau callback, xác nhận bằng DBeaver:

```sql
SELECT id, booking_id, amount, payment_method, status,
       gateway_transaction_ref, gateway_transaction_no, gateway_response_code, paid_at
FROM payments
ORDER BY id DESC;
```

Kỳ vọng: `payment_method = 'VNPAY'`, `status = 'PAID'`, có transaction reference và callback data.

## Tiêu chí kết luận demo hoàn chỉnh

- Đăng ký, đăng nhập, refresh token và `/auth/me` thành công.
- Customer chỉ xem/sửa Pet và Booking của mình.
- Provider chỉ quản lý Service, Staff và Schedule của chính họ.
- Booking bị từ chối khi Staff trùng lịch.
- Gợi ý chỉ trả dịch vụ phù hợp loài thú cưng; có thời gian đặt thì ưu tiên Provider còn lịch.
- Workflow Bonita vẫn duyệt Provider ở back-office.
- VNPAY Sandbox tạo payment URL, nhận IPN có chữ ký hợp lệ và cập nhật payment thành `PAID`.
