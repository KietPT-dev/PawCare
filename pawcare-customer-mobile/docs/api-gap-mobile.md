# Mobile API gaps

After synchronizing with `master`, the Customer app has API coverage for
booking, wallet, pets, care notes, reviews, disputes and notifications.

Resolved: `PUT /api/v1/notifications/read-all`, authenticated, with an empty
request and `{ "success": true, "updated": number }` response.

## Remaining gap

- `PUT /api/v1/me/notification-preferences` is not available. The Customer
  app therefore shows booking/reminder preference controls as disabled with
  “Sắp hỗ trợ”, rather than pretending that a local switch has updated the
  server. Expected request: `{ "bookingUpdates": true, "careReminders": true
  }`; expected response: the saved preference object.

- `GET /api/v1/providers` now returns `average_rating` and `review_count`.
  It still does not return `approved_at` or `created_at`, so the Customer app
  transparently keeps “Mới” unavailable instead of claiming a false sort.
  Expected additional field: `{ "approved_at": "2026-11-24T10:30:00" }`.
