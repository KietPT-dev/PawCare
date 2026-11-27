# Provider API gaps

## Provider location and cover status

Resolved on backend migration `015_provider_location_and_cover.sql`:

- `GET/PUT /api/v1/provider/me` exposes structured address and geocode state.
- `POST /api/v1/provider/me/cover` accepts multipart field `file` (JPEG, PNG,
  WebP; maximum 5 MiB by default) and returns `coverImageUrl`.
- `DELETE /api/v1/provider/me/cover` clears the stored cover.

There is no current Provider Web API gap for address, geocoding status or cover
management.

## Provider registration and email verification

Resolved using existing Core endpoints in `public-api`:

- `POST /api/v1/auth/register` creates a `user_profiles` row (`email_verified = 0`, `role = PROVIDER`) and a `providers` row (`status = PENDING`, `providerType = SHOP | INDIVIDUAL`, `providerName`, `phone`, `address`), returning an active session token.
- `POST /api/v1/auth/email-verification/request` (authenticated with Bearer `accessToken`) issues a 30-minute single-use `EMAIL_VERIFY` token and queues transactional email delivery via `ResendTransactionalEmailSender`.
- `POST /api/v1/auth/email-verification/confirm` (`{ token }`) completes email verification (`email_verified = 1`).
- `GET /api/v1/auth/me` refreshes `emailVerified` status.

Operational notes (Core deployment configuration, outside Provider Web scope):

- `AuthService.register()` does not automatically dispatch a verification email inside `/auth/register`, so Provider Web invokes `POST /api/v1/auth/email-verification/request` immediately after registration completes and provides a resend + token confirmation screen.
- `PAWCARE_APP_DEEP_LINK_BASE` defaults to `pawcare://auth` in `public-api` (shared with Customer Mobile). Until an environment configures a dedicated web link base or email delivery (`PAWCARE_MAIL_PROVIDER=RESEND`), users can verify via `/verify-email?token=...` or paste either the verification link or token directly on the Provider verification screen.
