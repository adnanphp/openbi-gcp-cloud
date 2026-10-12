# Observability — Cloud Logging + Cloud Monitoring

GCP's logging and metrics stack. Replaces Loki + Prometheus.

## Log routing
GKE pods
│ stdout
▼
Cloud Logging (automatic via the GKE agent)
│
├── _Default bucket (30-day retention, all logs)
└── openbi-dev-logs bucket (30-day retention, OpenBI only)

text

**Log sink:** routes logs matching a filter to a dedicated bucket. The
filter for OpenBI:
resource.type="k8s_container"
AND resource.labels.namespace_name="openbi"

text

**Why a dedicated bucket:** retention, access control, and export can
be managed separately from the default bucket. Cost tracking also
becomes simpler.

## Log-based metrics

Two metrics extracted from OpenBI logs:

| Metric | Source | Use |
| --- | --- | --- |
| `openbi-dev/error_count` | Count of `severity=ERROR` logs | Alerting on error spikes |
| `openbi-dev/fastapi_latency_ms` | Extracted `duration_ms` from JSON logs | Latency distribution, P99 |

The second uses `value_extractor = "EXTRACT(jsonPayload.duration_ms)"`,
which pulls a numeric field out of a JSON log line. This is why
**structured JSON logging matters** — it enables metric extraction
without regex.

## Dashboard

One Cloud Monitoring dashboard, `openbi-dev — OpenBI Platform`, with
three tiles:

- Cloud SQL CPU utilization (last 6 hours)
- Pub/Sub DLQ undelivered messages
- GKE container restarts per second

JSON-defined, created via `google_monitoring_dashboard`.

## Alerts

Three alert policies, same as the AWS repo:

| Alert | Fires when | Duration |
| --- | --- | --- |
| Cloud SQL CPU high | CPU > 80% | 10 min |
| DLQ backlog | undelivered messages > 0 | 1 min |
| LB 5xx high | 5xx rate > 5% | 5 min |

Each sends to the same notification channel (email). Real notifications
require a verified email address.

**Why only three:** alarm fatigue is real. These cover compute
saturation, pipeline failures, and user-facing errors.

## Notification channels

GCP requires an explicit channel. Email is the simplest; Slack and
PagerDuty require additional setup.

Set `notification_email` in the composition to a real address. Verify
the email in the Cloud Console before alerts are delivered.

## Secret Manager

Replaces plain-text Kubernetes Secrets.

**The pattern:**
Secret Manager (secret: openbi/dev/db)
│
│ ESO reads via Workload Identity
▼
External Secrets Operator
│
│ creates/updates K8s Secret
▼
Kubernetes Secret (openbi-db-credentials)
│
│ mounted by
▼
Application Pod

text

The GSA (`openbi-dev-eso`) has `roles/secretmanager.secretAccessor`
scoped by IAM condition to secrets under `openbi/dev/`.

## Workload Identity binding

The KSA → GSA binding:

```hcl
resource "google_service_account_iam_member" "eso_workload_identity" {
  service_account_id = google_service_account.eso.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:PROJECT.svc.id.goog[external-secrets/external-secrets]"
}
The KSA annotation on the ESO ServiceAccount tells GKE which GSA to
expose.

GCP vs AWS
GCP	AWS
Cloud Logging	CloudWatch Logs
Log sink	Subscription filter
Log-based metric	Metric filter
Cloud Monitoring	CloudWatch Metrics
Alert policy	CloudWatch Alarm
Notification channel	SNS topic + subscription
Dashboard (JSON)	Dashboard (JSON)
Secret Manager	Secrets Manager
Workload Identity	IRSA
GCP SA + KSA binding	IAM role + OIDC trust
Verification status
Not verified against real GCP. Statically validated. See docs/verification.md.
