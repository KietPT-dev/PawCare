# Provider API gaps

## Provider address geocoding and cover image

The current Provider contract only supports the flat `address` string on
`GET/PUT /api/v1/provider/me`. It does not expose ward, district, province,
latitude, longitude, geocode status, or a cover image URL.

Required additions:

- Structured address fields and read-only geocode result (`latitude`,
  `longitude`, `geocodeStatus`) on `/provider/me`.
- Provider-authorised cover endpoints: upload, replace and delete. The upload
  contract must define accepted MIME types, maximum bytes and return a stored
  URL; clients must send multipart data, never base64 data in the database.
- Public Provider discovery response must include the cover URL and geocoded
  location so Customer Mobile can render fallback images and delegate distance
  sorting to backend.
