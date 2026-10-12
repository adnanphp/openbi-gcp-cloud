# OpenBI Application Manifests

Kustomize manifests for running OpenBI on GKE.

## What runs as Kubernetes workloads

- **FastAPI** (2 replicas) — with Cloud SQL Auth Proxy sidecar
- **Superset** (1 replica) — with Cloud SQL Auth Proxy sidecar

## What's replaced by managed services

| Local (Kind) | GKE |
| --- | --- |
| Postgres | **Cloud SQL** (G6) |
| MinIO | **Cloud Storage** (G5) |
| Kafka | **Pub/Sub** (G7) |
| Redis | *(not included — could be Memorystore)* |
| LocalStack | **real GCP** |
| OpenFaaS | *(not included — could be Cloud Run)* |
| Loki + Promtail | **Cloud Logging** (automatic in GKE) |
| Prometheus | **Cloud Monitoring** (G9) |

## No DaemonSets needed

Unlike EKS (which needed Fluent Bit and the CloudWatch agent as
DaemonSets), GKE ships container logs and system metrics to Cloud
Logging and Cloud Monitoring automatically. No additional components
to install.

## Applying

```bash
# Replace placeholders first (see "Placeholders" below), then:

kubectl apply -k kubernetes/openbi-app/overlays/dev
Placeholders
Several values must be substituted from Terraform outputs before
applying:

Placeholder	Where	From
REPLACE-WITH-FASTAPI-GSA-EMAIL	base/service-account.yaml	terraform output -raw fastapi_gsa_email
REPLACE-WITH-PROJECT-ID	base/configmap.yaml	GCP project ID
openbi-raw-REPLACE	base/configmap.yaml	terraform output -raw gcs_raw_bucket
openbi-events-REPLACE	base/configmap.yaml	terraform output -raw pubsub_main_topic
REPLACE-WITH-ARTIFACT-REGISTRY-URL	base/fastapi-deployment.yaml	terraform output -raw artifact_registry_url
REPLACE-WITH-PROJECT-ID	kubernetes/external-secrets/cluster-secret-store.yaml	GCP project ID
A future enhancement will automate substitution in deploy.sh.

Prerequisites
The openbi namespace exists

The gcp-secret-manager ClusterSecretStore exists

The openbi/dev/db and openbi/dev/superset secrets exist in Secret Manager

The OpenBI FastAPI image is pushed to Artifact Registry

Verifying
bash
kubectl -n openbi get pods
kubectl -n openbi get ingress
kubectl -n openbi get externalsecret
Expected:

fastapi-* pods have 2 containers each (fastapi + cloud-sql-proxy)

Both ExternalSecret resources show SecretSynced

Ingresses have an ADDRESS (the reserved static IP)
