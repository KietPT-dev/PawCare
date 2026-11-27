# Provider Approval 1.1 – bridge Bonita ↔ PawCare

`providers` remains the canonical approval state. Bonita owns the human task and
orchestration only; it must call the callback below after the Admin completes the
**Xét duyệt** task. This means a retry in Bonita cannot approve/reject a provider
twice.

## 1. Apply and configure

1. Apply [`database/014_provider_approval_workflow_bridge.sql`](../database/014_provider_approval_workflow_bridge.sql) once.
2. Deploy and enable the **ProviderApproval 1.1** process in Bonita. Map its
   `Administrator` actor to `/PawCare/Administrators : Administrator`.
3. Start the Public API with these environment variables (do not commit their
   actual values):

```bash
PAWCARE_BONITA_PROVIDER_APPROVAL_ENABLED=true
PAWCARE_BONITA_PROVIDER_APPROVAL_USERNAME=pawcare.workflow
PAWCARE_BONITA_PROVIDER_APPROVAL_PASSWORD='the Bonita password'
PAWCARE_BONITA_PROVIDER_APPROVAL_BRIDGE_TOKEN='a-long-random-shared-secret'
```

The deployment must generate a new bridge token and set it in both the API
environment and the two Bonita REST connectors. The tracked diagram contains
only a deployment placeholder, never a usable token. Configure its connector
value in Bonita immediately before deployment; do not save a real token back
into the project source.

The API user must be mapped to the ProviderApproval actors only if it needs to
claim/execute tasks. The recommended mapping is `pawcare.workflow` as an
additional allowed user, while administrators remain mapped through their normal
membership.

## 2. Configure the two Bonita REST service tasks

For both service tasks add a **REST API** connector *on enter*. In a local setup:

| Task | Method | URL | JSON body |
| --- | --- | --- | --- |
| Đồng bộ duyệt Provider | POST | `http://127.0.0.1:8081/api/v1/internal/provider-approval/synchronize` | `{"providerId": ${providerId}, "decision": "APPROVED", "reviewNote": ${reviewNote}}` |
| Đồng bộ từ chối Provider | POST | `http://127.0.0.1:8081/api/v1/internal/provider-approval/synchronize` | `{"providerId": ${providerId}, "decision": "REJECTED", "reviewNote": ${reviewNote}}` |

Set the headers:

```text
Content-Type: application/json
X-PawCare-Workflow-Token: <same PAWCARE_BONITA_PROVIDER_APPROVAL_BRIDGE_TOKEN>
```

Use a Bonita Groovy/JSON expression for the body instead of concatenating the
review note raw. For example, make the connector body expression produce:

```groovy
groovy.json.JsonOutput.toJson([
  providerId: (providerId as Long),
  decision: 'APPROVED',
  reviewNote: reviewNote ?: ''
])
```

For the rejection task replace `APPROVED` with `REJECTED`. `caseId` is optional;
the Public API checks the provider ID and performs an idempotent transition.

## 3. Runtime path

1. Provider registration inserts a durable `START` outbox event.
2. The Public API scheduler starts a Bonita case and stores its case ID on the
   provider record. Failed starts can be retried with
   `POST /api/v1/admin/providers/{providerId}/workflow/retry`.
3. The Admin application calls
   `POST /api/v1/admin/providers/{providerId}/workflow/decision` with
   `{ "decision": "APPROVED|REJECTED", "reviewNote": "..." }`.
4. The API completes Bonita's **Xét duyệt** task; it does **not** update the
   provider itself.
5. The selected service task calls the secured callback. Only then does PawCare
   update `providers.status`, create one notification and one audit record.

## 4. Verify a live case

After registering a Provider, inspect `GET /api/v1/admin/providers/{providerId}/workflow`
as an Admin. A healthy bridge has a non-null `provider.bonita_case_id` and a
`START` outbox event with `status=SENT`. `FAILED` retains a safe operational
error and can be retried with `POST /api/v1/admin/providers/{providerId}/workflow/retry`.
While the case is pending, business endpoints return
`PROVIDER_APPROVAL_REQUIRED`; they must never grant access just because the
Provider account can log in.

The callback accepts `X-PawCare-Workflow-Token`, `Authorization: Bearer …`, or
`Authorization: Apikey …`. Keep the token only in environment/configuration,
never in the process source, browser code, or Git.
