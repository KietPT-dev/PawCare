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
