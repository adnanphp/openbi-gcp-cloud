# GKE Deployment

End-to-end view of how OpenBI runs on GKE.

## The pod-to-GCP path

When a FastAPI pod starts:
Kubelet pulls the image from Artifact Registry
Uses the node SA (roles/artifactregistry.reader)

Pod schedules on a node (primary or spot pool)

Pod's KSA (openbi/fastapi) is annotated with a GSA email
(iam.gke.io/gcp-service-account: openbi-dev-fastapi@PROJECT.iam.gserviceaccount.com)

GKE's metadata server injects a token for that GSA
No keys. No files. The token is served over the metadata endpoint.

The cloud-sql-proxy sidecar reads the token and connects to Cloud SQL
--auto-iam-authn means the proxy uses IAM auth, not password auth

The FastAPI container connects to 127.0.0.1:5432
(the sidecar's local listener)

External Secrets Operator (in external-secrets namespace)
reads openbi/dev/db from Secret Manager and creates the K8s Secret
FastAPI mounts the Secret as DB_USER, DB_PASSWORD

FastAPI reads/writes GCS objects using its GSA (via the metadata server)

FastAPI publishes to Pub/Sub using its GSA

Container stdout goes to Cloud Logging automatically (GKE ships it)
System metrics go to Cloud Monitoring automatically

text

## Order of operations
terraform apply
│
├── VPC, IAM, Artifact Registry, GKE, GCS, Cloud SQL, Pub/Sub,
│ Load Balancing, Logging, Monitoring, Secrets, Workload Identity
│
▼
gcloud container clusters get-credentials openbi-dev --region europe-west3
│
▼
helm install external-secrets (with GSA annotation)
│
▼
kubectl apply -f kubernetes/external-secrets/cluster-secret-store.yaml
│
▼
kubectl apply -k kubernetes/openbi-app/overlays/dev
│
▼
OpenBI workloads running

text

## What's different from AWS

| Aspect | AWS (EKS) | GCP (GKE) |
| --- | --- | --- |
| Pod identity | IRSA (annotation on KSA + OIDC trust) | Workload Identity (annotation + GSA binding) |
| DB connection | Direct to RDS private IP | Cloud SQL Auth Proxy sidecar |
| Secrets | Secrets Manager + ESO | Secret Manager + ESO (same tool, different provider) |
| Log shipping | Fluent Bit DaemonSet | Automatic (GKE ships logs) |
| Metrics | CloudWatch agent DaemonSet | Automatic (GKE ships metrics) |
| Ingress controller | AWS Load Balancer Controller (Helm install) | GKE Ingress (built-in) |
| Ingress class | `alb` | `gce` |
| Static IP | None (ALB gets one) | Reserve a global static IP |

## What's not in G10

- **Memorystore for Redis** — documented as a gap
- **Cloud Run for serverless** — documented as a gap
- **HorizontalPodAutoscaler (HPA)** — future work
- **PodDisruptionBudgets** — future work
- **NetworkPolicies** — future work

## Verification status

**Not verified against real GCP.** Statically validated. See `docs/verification.md`.
