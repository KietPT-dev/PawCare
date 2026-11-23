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

- `GET /api/v1/providers` currently returns `average_rating`, but not a
  review count or catalogue timestamp. The app derives `reviewCount` from the
  existing `GET /api/v1/reviews?providerId={id}` data when available, so it
  never invents a star count. For efficient cards and a genuine “Mới” sort,
  the provider list should additionally return `review_count` and
  `approved_at` (or `created_at`) for each provider. Expected fields:
  `{ "average_rating": 4.8, "review_count": 12, "approved_at": "..." }`.
