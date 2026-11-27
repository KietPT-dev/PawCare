# Bonita Admin API gaps and deployment guide

## Current API extension endpoints

Admin pages use the authenticated Bonita REST extension only:

- `GET /bonita/API/extension/bookings`
- `GET|PUT /bonita/API/extension/complaints`
- `GET|PUT|POST /bonita/API/extension/finance`
- `GET|PUT /bonita/API/extension/users`
- `GET|PUT /bonita/API/extension/providers`
- `GET|POST|PUT|DELETE /bonita/API/extension/categories`

The upstream service also exposes the authoritative Admin contracts below. They
are useful when extending the REST extension, but UI Designer pages must not
embed public-API credentials or call them as an anonymous substitute:

- `GET /api/v1/admin/reports/finance?from=yyyy-MM-dd&to=yyyy-MM-dd`
- `GET /api/v1/admin/withdrawals?status=PENDING|APPROVED|REJECTED`
- `PUT /api/v1/admin/withdrawals/{id}`
- `GET /api/v1/admin/disputes?status=...`
- `POST /api/v1/admin/disputes/{id}/resolve`

The `pawcare_api` permission must be assigned to the Bonita Administrator profile. The extension resolves the caller's Bonita account to `user_profiles`; only rows with `role_code=ADMIN` can read or mutate finance, dispute and back-office data.

## API gaps (do not fake these in the UI)

- Provider identity/document uploads have no REST-extension endpoint or document storage metadata. The Provider page must show the existing approval state only; it must not expose a fake document-review action.
- Booking detail does not currently expose a joined Bonita case/task id, customer/service/escrow payload in one extension response. Add a read-only `booking-detail` endpoint before rendering those fields as authoritative.
- Workflow visibility is partial: Finance records retain `bonita_case_id` when
  supplied, but the extension has no read-only endpoint that joins Bonita case,
  pending task and marketplace booking. Do not infer a task state from a wallet
  transaction or booking status.
- The public API's booking orchestration should remain the authority for status changes. Do not let generic Admin widgets submit arbitrary booking statuses.
- Conversation moderation is available to Bonita Admin through authenticated REST
  extension adapters: `GET|PUT /bonita/API/extension/conversation-reports` and
  `GET /bonita/API/extension/conversation-messages?conversation_id=...`. They mirror
  the Public API moderation contract for report filtering/pagination, state changes
  (`OPEN`, `REVIEWED`, `DISMISSED`) and audited reported-conversation reads. The
  message route rejects conversations without a report. No general inbox, message
  mutation route, token, or public-API secret is exposed to UI Designer resources.
- AI risk alerts and operational recommendations (`AdminPawCareAiAlerts` / `AdminPawCareAiRecommendations`) call the upstream Admin contracts (`/api/v1/admin/ai/risk-scores`, `/api/v1/admin/ai/risk-scores/{id}`, `/api/v1/admin/ai/risk-scores/{id}/review`, `/api/v1/admin/ai/operational-recommendations`, `/api/v1/admin/ai/operational-recommendations/{id}/review`), and the following backend gaps currently exist and must not be mocked in the UI:
  - **Missing Bonita REST extension proxy / session bridge**: `AiAdminController` sits on `public-api` behind JWT `Bearer` authentication (`JwtAuthenticationFilter`), whereas Bonita Portal pages authenticate with Bonita session cookies and must not embed `public-api` credentials (`PAWCARE_JWT_SECRET` or user tokens). Either a same-origin reverse proxy mapping `/api/v1/admin/ai/*` with shared Admin session verification or Bonita REST extension adapters (`/bonita/API/extension/ai-...`) is required in `extensions/pawcareAPI` for seamless Bonita Portal calls.
  - **Missing `payload` column in `GET /api/v1/admin/ai/operational-recommendations`**: `AiAdminController.recommendations()` selects `id, recommendation_type, subject_name, model_name, model_version, score, confidence, status, created_at, reviewer_profile_id, reviewed_at, reviewer_note` and omits the `payload` JSON column from `ai_operational_recommendations`. Because `payload` is not returned, structured `INDEX` fields (`candidate_columns`, `recommendation`, `reason`) and `CAPACITY_FORECAST` fields (`threshold`, `predicted_days_to_threshold`, `assumption`, `warning`) cannot be populated from the API yet.
  - **Missing total & summary counts in `GET /api/v1/admin/ai/risk-scores`**: the endpoint returns `{ items, page, size }` without `totalElements`, `totalPages`, or global counts for `OPEN`, `HIGH`, and `REVIEWED`. The UI displays per-page counts accurately rather than fabricating global totals.
  - **Missing `reviewer_name` join**: both `ai_risk_scores` and `ai_operational_recommendations` return `reviewer_profile_id` only without joining `user_profiles.full_name`.

## Export/import and deployment

1. Run `mvn test` at the repository root; it validates UI Designer resources and creates the Business Archive.
2. In Bonita Studio, select **BookingService 2.0** and deploy the generated process; map `Customer`, `Provider`, and `Admin` actors to their intended groups before enabling it. The task **Đặt lịch** is mapped to `PawCareBookingRequestForm`; other unmapped workflow tasks explicitly use `NONE` until their business contracts and task forms are specified.
3. Export the custom pages/widgets from the project or import the project resource ZIP into the target Studio. Import the REST extension ZIP before navigating to Admin pages.
4. Deploy `PawCareAdmin` application descriptor, then add/verify menu entries for Booking, Tài chính sàn, Tranh chấp and Báo cáo hội thoại.
5. Clear the browser cache (or use a private window) and reload the Bonita portal after page/widget deployments.

No passwords, access tokens, database credentials, or public-API secrets belong in UI Designer resources or exported ZIPs.
