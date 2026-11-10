# Provider API gaps

## Review reply

Provider Web displays reviews in read-only mode. The backend exposes
`GET /api/v1/provider/reviews`, but has no provider-authorised endpoint or data
model for a response to a review.

Suggested contract: `POST /api/v1/provider/reviews/{reviewId}/reply` with
`{ "content": "..." }`, returning the persisted reply, author and timestamp.
The endpoint must verify that the review belongs to the authenticated Provider.
