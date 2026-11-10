# Provider API gaps

## Review reply

Resolved on backend migration `011_review_replies.sql`:

- `POST /api/v1/provider/reviews/{reviewId}/reply`
- Body: `{ "content": "..." }`
- The API verifies that the review belongs to the authenticated Provider and
  returns the persisted reply, author profile id and timestamp.
