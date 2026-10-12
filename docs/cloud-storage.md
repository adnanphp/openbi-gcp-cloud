# Cloud Storage

GCP's object storage. Replaces MinIO in the OpenBI deployment.

## Buckets

Three buckets mirror the OpenBI data lifecycle:

| Bucket | Purpose | Versioning | Lifecycle |
| --- | --- | --- | --- |
| `openbi-raw-<suffix>` | Source data | On | → Nearline @30d → Coldline @90d → Archive @365d, delete @730d |
| `openbi-processed-<suffix>` | Cleaned/derived data | Off | Delete @90d |
| `openbi-models-<suffix>` | ML artifacts | On | Non-current versions delete @90d |

The `<suffix>` is the GCP project ID, giving globally-unique names.

## Design decisions

### Uniform bucket-level access

All access via IAM, no per-object ACLs. This is the modern GCP default
and the only recommended mode. Enabled explicitly.

### Public access prevention

`public_access_prevention = "enforced"` — even an accidental IAM
binding to `allUsers` cannot make objects public.

### Encryption

Google-managed keys by default. No configuration required. CMEK is
available via `encryption { default_kms_key_name = ... }` for teams
that need key control.

### Storage classes

GCP storage classes (from cheapest-but-slowest to most expensive):

| Class | Access pattern |
| --- | --- |
| ARCHIVE | Retrieval in hours, cheapest |
| COLDLINE | Retrieval in seconds, very cheap |
| NEARLINE | Access < 1/month |
| STANDARD | Frequent access |

The `raw` bucket transitions STANDARD → NEARLINE → COLDLINE → ARCHIVE
over two years, then deletes. Objects that are never read again cost
almost nothing after the first year.

## Access

No roles are granted by default. To give a service account read access:

```hcl
module "storage" {
  # ...
  additional_reader_members = [
    "serviceAccount:openbi-dev-fastapi@${var.project_id}.iam.gserviceaccount.com",
  ]
}
This grants roles/storage.objectViewer on all three buckets. For
write access or bucket-scoped access, use google_storage_bucket_iam_member
directly in the consuming module.

Signed URLs
Temporary, credential-free URLs that grant access to a specific object.
The GCP equivalent of AWS S3 presigned URLs.

In GKE with Workload Identity, signing requires calling the IAM
SignBlob API (the pod doesn't hold a private key). The
google-cloud-storage SDK supports this via generate_signed_url with
the correct credentials setup. See the Python script for the pattern.

Applying
bash
cd terraform/environments/dev
terraform apply -var="resource_suffix=$(gcloud config get-value project)"
Verifying
bash
gcloud storage buckets list --project=PROJECT_ID
gcloud storage ls gs://openbi-raw-PROJECT_ID/
GCP vs AWS
GCP	AWS
Cloud Storage	S3
Bucket	Bucket
Object	Object
Uniform bucket-level access	IAM + bucket policy
Public access prevention	Block Public Access
Lifecycle rules	Lifecycle policies
Nearline/Coldline/Archive	Standard-IA / Glacier / Deep Archive
Signed URL	Presigned URL
Google-managed encryption	SSE-S3
CMEK	SSE-KMS
Verification status
Not verified against real GCP. Statically validated. See docs/verification.md.
