# Deployment Guide

End-to-end deployment of OpenBI on GCP.

## ⚠️ Not verified

This procedure has **not been executed against a real GCP project**.
The Terraform modules and manifests are correct as written. Live
deployment is untested. See `verification.md`.

## Prerequisites

| Tool | Purpose |
| --- | --- |
| gcloud CLI | GCP API access, auth |
| Terraform ≥ 1.5 | Infrastructure provisioning |
| kubectl | Kubernetes access |
| Helm ≥ 3.13 | External Secrets Operator install |
| Docker | Building the FastAPI image |
| jq | Output formatting |

Plus:

- A GCP project with billing enabled
- Your account has `roles/owner` or equivalent (VPC, GKE, Cloud SQL, IAM, Secret Manager, Artifact Registry, Pub/Sub, Logging, Monitoring)
- The Cloud SQL Admin API, GKE API, Secret Manager API, Artifact Registry API, Pub/Sub API enabled on the project

Enable the APIs once:

```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com \
  pubsub.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  servicenetworking.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com
Quick start
bash
# Dry-run
./scripts/deploy.sh

# Apply
./scripts/deploy.sh --apply
Manual deployment
1. Set project
bash
gcloud config set project YOUR-PROJECT-ID
gcloud config set compute/region europe-west3
2. Terraform
bash
cd terraform/environments/dev
terraform init
terraform apply -var="resource_suffix=$(gcloud config get-value project)"
Provisions:

VPC, subnet with secondary ranges, Cloud NAT, firewall rules

IAM: node SA, workload identity template SA

Artifact Registry (Docker)

GKE regional cluster with primary + spot node pools

Cloud Storage (raw, processed, models)

Cloud SQL PostgreSQL with Private Service Access

Pub/Sub topic + subscription + DLQ

Static IP for the load balancer

Log bucket, log-based metrics, monitoring dashboard, alerts

Secret Manager + ESO service account

Workload Identity binding for FastAPI

Time: ~20–25 minutes.

3. kubectl
bash
gcloud container clusters get-credentials openbi-dev --region europe-west3
kubectl get nodes
4. External Secrets Operator
bash
cd terraform/environments/dev
ESO_GSA=$(terraform output -raw eso_service_account_email)

helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set serviceAccount.name=external-secrets \
  --set serviceAccount.annotations."iam\.gke\.io/gcp-service-account"=$ESO_GSA
5. Kubernetes resources
bash
kubectl apply -f kubernetes/namespaces/
kubectl apply -f kubernetes/external-secrets/cluster-secret-store.yaml
6. Substitute placeholders
The openbi-app manifests contain REPLACE-WITH-* and REPLACE
tokens. Replace them from Terraform outputs:

bash
cd terraform/environments/dev

# ServiceAccount GSA
GSA=$(terraform output -raw fastapi_gsa_email)
sed -i "s|REPLACE-WITH-FASTAPI-GSA-EMAIL|$GSA|" ../../kubernetes/openbi-app/base/service-account.yaml

# Project ID
PROJECT=$(gcloud config get-value project)
sed -i "s|REPLACE-WITH-PROJECT-ID|$PROJECT|g" ../../kubernetes/openbi-app/base/configmap.yaml
sed -i "s|REPLACE-WITH-PROJECT-ID|$PROJECT|g" ../../kubernetes/external-secrets/cluster-secret-store.yaml

# GCS buckets
RAW=$(terraform output -raw gcs_raw_bucket)
PROC=$(terraform output -raw gcs_processed_bucket)
MODELS=$(terraform output -raw gcs_models_bucket)
sed -i "s|openbi-raw-REPLACE|$RAW|" ../../kubernetes/openbi-app/base/configmap.yaml
sed -i "s|openbi-processed-REPLACE|$PROC|" ../../kubernetes/openbi-app/base/configmap.yaml
sed -i "s|openbi-models-REPLACE|$MODELS|" ../../kubernetes/openbi-app/base/configmap.yaml

# Pub/Sub
TOPIC=$(terraform output -raw pubsub_main_topic)
SUB=$(terraform output -raw pubsub_main_subscription)
sed -i "s|openbi-events-REPLACE|$TOPIC|" ../../kubernetes/openbi-app/base/configmap.yaml
sed -i "s|openbi-events-sub-REPLACE|$SUB|" ../../kubernetes/openbi-app/base/configmap.yaml

# Artifact Registry URL
AR=$(terraform output -raw artifact_registry_url)
sed -i "s|REPLACE-WITH-ARTIFACT-REGISTRY-URL|$AR|" ../../kubernetes/openbi-app/base/fastapi-deployment.yaml
7. Push the FastAPI image
bash
cd ../../..
./scripts/build-and-push.sh \
  "$(cd terraform/environments/dev && terraform output -raw artifact_registry_url)" \
  v0.1.0
8. Create remaining secrets
bash
# Superset secret key
gcloud secrets create openbi/dev/superset \
  --replication-policy="automatic" \
  --data-file=<(echo -n "{\"secret_key\": \"$(openssl rand -hex 32)\"}")
(The openbi/dev/db secret was created automatically by the Cloud SQL module.)

9. Apply OpenBI
bash
kubectl apply -k kubernetes/openbi-app/overlays/dev
10. Verify
bash
kubectl -n openbi get pods
kubectl -n openbi get ingress
kubectl -n openbi get externalsecret
Accessing the load balancer
The static IP is reserved in Terraform. Get it:

bash
cd terraform/environments/dev
terraform output -raw lb_external_ip
Point your domain's DNS at that IP to enable the managed certificate.

Teardown
See teardown.md.

Troubleshooting
See troubleshooting.md.
