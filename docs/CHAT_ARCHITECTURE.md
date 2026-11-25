# PawCare booking chat v1

## Boundary

The Public API and MySQL are the canonical source of conversations and messages.
Each conversation is tied one-to-one with a booking. Bonita does not receive a
workflow event for messages and must not update their state.

Only the booking Customer and the Provider owner may open, list, read, send or
report a conversation. v1 accepts text/emoji only; it deliberately excludes
attachments, images, voice notes and live-location sharing.

## Delivery model

v1 uses durable REST records plus client polling. An open conversation may poll
`GET /api/v1/conversations/{id}/messages` about every five seconds; clients stop
polling in background or after leaving the screen. `clientMessageId` is the
idempotency boundary for a send retry. New messages write a generic notification
for the other participant without exposing message content in notification logs.

## Moderation and privacy

Participants can report a conversation. Admin may see only reported
conversations through the moderation endpoints; each view creates an audit event
containing metadata only. Admin may move an individual report between `OPEN`,
`REVIEWED` and `DISMISSED`, recording only report/conversation identifiers and
the status transition in the audit trail. A moderation retry with the same
status and reviewer note is idempotent. No general admin inbox exists, and a
moderation action never modifies a message. Retention, recall and legal-hold
policy must be defined before enabling deletion or attachments.

## Upgrade path to real time

Do not add WebSocket merely to replace stable polling. Introduce it when product
usage requires lower latency, together with JWT-authenticated handshake/session
authorization, reconnect/backoff behaviour, rate limits, reverse-proxy WebSocket
support and a shared broker (Redis/RabbitMQ) for multiple API instances. MySQL
records and REST recovery remain the source of truth after that upgrade.
