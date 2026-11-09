# Bonita BookingService — vận hành cùng Public API

## Mục tiêu kiến trúc

Customer Mobile và Provider Web **không** đăng nhập Bonita. Chúng chỉ gọi
Public API. Public API là nguồn dữ liệu giao dịch duy nhất (booking, escrow,
ví, notification). Sau mỗi thay đổi đã commit, Public API ghi một event vào
`booking_workflow_outbox`; bridge sẽ gọi Bonita Engine REST để tạo/hoàn tất task.

Điều này tránh việc một lỗi Bonita làm rollback hoặc làm sai số dư ví. Các event
thất bại ở `FAILED` và Admin có thể xem/retry qua API nội bộ.

## Migration

Chạy một lần trong DBeaver, sau `007_two_party_completion_and_reporting.sql`:

`database/008_bonita_booking_orchestration.sql`

Nó thêm `bookings.bonita_case_id`, `bookings.bonita_process_definition_id` và
bảng outbox. Không chạy lại script này nếu cột đã tồn tại.

## BookingService v2 cần cấu hình trong Bonita Studio

Diagram hiện tại chỉ mới đi đến quyết định Provider duyệt/từ chối. Để bridge
vận hành đủ luồng hai phía, tạo version mới của `BookingService` với đúng tên
task và biến dưới đây (không đổi tên tùy ý):

| Bước | Loại / actor | Tên task trong Bonita | Public API event |
|---|---|---|---|
| Bootstrap sau Escrow | Human task, actor `Customer` kỹ thuật | `Đặt lịch` | `START` tự hoàn tất |
| Provider chọn duyệt/từ chối | Human task, actor `Provider` kỹ thuật | `Xác nhận lịch` | `PROVIDER_APPROVED` / `PROVIDER_REJECTED` |
| Provider báo xong | Human task, actor `Provider` kỹ thuật | `Báo hoàn tất dịch vụ` | `PROVIDER_SERVICE_DONE` |
| Customer xác nhận/khiếu nại | Human task, actor `Customer` kỹ thuật | `Xác nhận hoàn tất` | `CUSTOMER_CONFIRMED` / `CUSTOMER_DISPUTED` |
| Admin xử lý khiếu nại | Human task, actor `Admin` | `Xử lý tranh chấp` | `ADMIN_RELEASE_TO_PROVIDER` / `ADMIN_REFUND_TO_CUSTOMER` |

Tạo các process data sau:

* `bookingId` (Long, mặc định `0`) — mã booking thật trong MySQL/PawCare.
* `bookingAccepted` (Boolean, mặc định `false`) — gateway sau `Xác nhận lịch`.
* `customerDecision` (Text) — `CONFIRM` hoặc `DISPUTE`.
* `disputeDecision` (Text) — `RELEASE_TO_PROVIDER` hoặc `REFUND_TO_CUSTOMER`.

Luồng BPMN:

```text
Đặt lịch (technical bootstrap)
  → Xác nhận lịch
  → [bookingAccepted?] → Từ chối → End
                       → Đã duyệt → Báo hoàn tất dịch vụ
                         → Xác nhận hoàn tất
                         → [customerDecision]
                            CONFIRM → End
                            DISPUTE → Xử lý tranh chấp → End
```

Các Service Task của Bonita chỉ dùng gửi notification/audit nếu cần. Chúng
không được tự ý sửa `wallets` hoặc `bookings`; các thay đổi tài chính vẫn do
Public API transaction thực hiện.

### Actor mapping

Tạo một Bonita user kỹ thuật, ví dụ `pawcare.workflow`, rồi map user này vào
hai actor `Customer` và `Provider`. Đây không phải tài khoản đăng nhập của
khách/provider; chỉ là engine identity để bridge hoàn tất task đã được họ thao
tác từ giao diện PawCare. Actor `Admin` map vào Admin Bonita thật.

Deploy process version mới rồi **disable version cũ** để bridge luôn tìm đúng
process `BookingService` mới nhất.

## Bật bridge sau khi deploy

Thêm các giá trị này vào `.env.local` (file bị Git ignore, không commit mật khẩu):

```bash
PAWCARE_BONITA_WORKFLOW_ENABLED=true
PAWCARE_BONITA_URL=http://127.0.0.1:62666/bonita
PAWCARE_BONITA_USERNAME=pawcare.workflow
PAWCARE_BONITA_PASSWORD=<mat-khau-user-ky-thuat>
PAWCARE_BONITA_BOOKING_PROCESS=BookingService
```

Khởi động lại Public API. Một booking được thanh toán sau đó sẽ sinh case
Bonita tự động. Với booking cũ, Admin có thể xem/retry:

* `GET /api/v1/admin/bookings/{bookingId}/workflow`
* `POST /api/v1/admin/bookings/{bookingId}/workflow/retry`

## Kiểm thử end-to-end

1. Customer tạo booking và nạp/giữ escrow. `bonita_case_id` phải có giá trị.
2. Provider duyệt; task `Xác nhận lịch` được complete và case đến bước báo xong.
3. Provider báo hoàn tất; case dừng tại `Xác nhận hoàn tất`, tiền vẫn locked.
4. Customer xác nhận; case kết thúc, ledger ghi payout 90% + fee 10%.
5. Tạo booking khác, chọn dispute; case đến `Xử lý tranh chấp`.
6. Admin quyết định refund/release; case hoàn tất và ledger khớp với quyết định.

Không bật `PAWCARE_BONITA_WORKFLOW_ENABLED` trước khi deploy/mapping process
v2: event sẽ retry vì task name/actor của process cũ chưa đủ cho luồng mới.
