# Mobile API gaps

After synchronizing with `master`, the Customer app has API coverage for
booking, wallet, pets, care notes, reviews, disputes and notifications.

Potential future API: `PUT /api/v1/notifications/read-all`, authenticated,
with an empty request and `{ "success": true, "updated": number }` response.
