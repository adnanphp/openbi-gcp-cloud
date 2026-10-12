# IAM and Workload Identity

GCP's identity model for GKE pods. The equivalent of AWS IRSA, with a
different trust mechanism.

## The two service accounts

| SA | Purpose |
| --- | --- |
| `<prefix>-gke-nodes` | Assumed by GKE nodes for logging, monitoring, registry read |
| `<prefix>-workload-template` | Template for pod-level service accounts |

The node SA replaces the default Compute Engine SA, which has `Editor`
— far too broad for a node that only needs to write logs and pull
images.

## Why not the default node SA

The default Compute Engine SA in a new project has `roles/editor`,
which grants write access to nearly every GCP resource. A compromised
node could create VMs, delete buckets, alter IAM. Restricting the node
SA to four narrow roles eliminates that blast radius.

## Workload Identity — the mechanism
Pod (Kubernetes ServiceAccount)
│
│ GKE injects a projected token
▼
GKE metadata server (per node)
│
│ Pod requests GCP credentials
▼
Google Cloud IAM validates the KSA identity
│
│ Returns short-lived OAuth token for the bound GSA
▼
Pod uses credentials (auto-refreshed)

text

The binding is established once per (KSA, GSA) pair:

```hcl
resource "google_service_account_iam_member" "ksa_binding" {
  service_account_id = google_service_account.this.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${namespace}/${ksa_name}]"
}
The member string is the "Workload Identity member identifier." It
encodes the project, the cluster's identity pool, and the
namespace/ServiceAccount.

No service account keys
GCP service account JSON keys are long-lived credentials. They are the
most common cause of GCP security incidents. This repository does not
use them anywhere. All pod-level GCP access goes through Workload
Identity.

How pods use this (future phases)
Each service module (GCS, Cloud SQL, Pub/Sub) will:

Create a GSA specific to that service (e.g. openbi-dev-fastapi-sa)

Grant the GSA only the roles that service needs

Bind the GSA to the KSA the pod runs as

The pod then accesses GCP APIs with no credentials in the manifest

Example for a pod that needs GCS access:

hcl
resource "google_service_account" "fastapi" {
  account_id = "openbi-dev-fastapi"
  project    = var.project_id
}

resource "google_project_iam_member" "fastapi_gcs" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.fastapi.email}"

  # Scoped to a specific bucket:
  condition {
    title      = "only-openbi-buckets"
    expression = "resource.name.startsWith('projects/_/buckets/openbi-')"
  }
}

resource "google_service_account_iam_member" "fastapi_ksa" {
  service_account_id = google_service_account.fastapi.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[openbi/fastapi]"
}
GCP vs AWS equivalents
GCP	AWS
Service Account	IAM Role
Workload Identity	IRSA (OIDC)
Workload Identity member identifier	Trust policy with oidc.eks... principal
roles/iam.workloadIdentityUser	sts:AssumeRoleWithWebIdentity
Predefined roles (roles/storage.objectAdmin)	AWS managed policies
IAM conditions	IAM policy conditions
No keys (WI only)	No keys (IRSA only)
The mental model is the same. The trust wiring looks different because
GKE handles it more transparently.
