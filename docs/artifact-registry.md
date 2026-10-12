# Artifact Registry

GCP's container registry. Holds the OpenBI images so GKE can pull them.

## Configuration

| Setting | Value |
| --- | --- |
| Format | Docker |
| Region | Matches the GKE cluster (e.g. `europe-west3`) |
| Repository ID | `openbi` |
| Cleanup: keep | last 10 tagged versions |
| Cleanup: delete | untagged after 7 days |

The cleanup policy mirrors the ECR lifecycle policy in the AWS repo.
Storage is cheap, but unbounded growth is a smell.

## URLs

Two forms, both valid:
Per-region (recommended — faster pull, lower egress)
europe-west3-docker.pkg.dev/PROJECT_ID/openbi

Multi-region
europe-docker.pkg.dev/PROJECT_ID/openbi

text

Use the regional URL. GKE clusters in the same region pull from it
without crossing regions.

## Image flow
Developer laptop
│
│ docker build
▼
Local image (e.g. openbi-fastapi:latest)
│
│ docker tag → Artifact Registry URL
▼
europe-west3-docker.pkg.dev/PROJECT/openbi:fastapi-v0.1.0
│
│ docker push
▼
Artifact Registry
│
│ imagePull (from GKE kubelet, using the node SA)
▼
GKE worker node
│
▼
OpenBI pods

text

The GKE node SA (from G2) has `roles/artifactregistry.reader`, so nodes
can pull without additional configuration.

## Push

```bash
./scripts/build-and-push.sh \
  europe-west3-docker.pkg.dev/PROJECT_ID/openbi \
  v0.1.0
The script:

Runs gcloud auth configure-docker for the registry host

Builds each OpenBI image from the source repo

Tags and pushes

Verify
bash
gcloud artifacts repositories list --location=europe-west3
gcloud artifacts docker images list \
  europe-west3-docker.pkg.dev/PROJECT_ID/openbi
GCP vs AWS
GCP	AWS
Artifact Registry	ECR
gcloud auth configure-docker	aws ecr get-login-password
Cleanup policies	Lifecycle policies
Repository-level IAM	Repository policies
Regional URL (REGION-docker.pkg.dev)	Account URL (ACCOUNT.dkr.ecr.REGION.amazonaws.com)
Verification status
Not verified against real GCP. Statically validated. See docs/verification.md.
