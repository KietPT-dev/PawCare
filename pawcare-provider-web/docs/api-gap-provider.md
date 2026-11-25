# Provider API gaps

## Provider location and cover status

Resolved on backend migration `015_provider_location_and_cover.sql`:

- `GET/PUT /api/v1/provider/me` exposes structured address and geocode state.
- `POST /api/v1/provider/me/cover` accepts multipart field `file` (JPEG, PNG,
  WebP; maximum 5 MiB by default) and returns `coverImageUrl`.
- `DELETE /api/v1/provider/me/cover` clears the stored cover.

There is no current Provider Web API gap for address, geocoding status or cover
management.
