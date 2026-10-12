# Architecture

Target GCP architecture for OpenBI.
User → Cloud Load Balancing → GKE Ingress
│
▼
GKE Cluster (Workload Identity)
├── FastAPI (2 replicas)
├── Superset (1 replica)
└── Cluster controllers
│
┌─────────────────────┼─────────────────────┐
▼ ▼ ▼
Cloud SQL Cloud Storage Pub/Sub
(PostgreSQL) (raw/processed/ (events + DLQ)
models)
│
▼
Cloud Logging / Monitoring
Secret Manager
Artifact Registry

text

## Design principles

1. **Workload Identity, no service account keys.** GKE pods assume GCP service accounts via Kubernetes ServiceAccount federation — the GCP equivalent of AWS IRSA.
2. **Private nodes, Cloud NAT for egress.** GKE node pools have no public IPs; egress goes through Cloud NAT.
3. **Custom-mode VPC.** Explicit subnet control, secondary ranges for GKE pods and services.
4. **Regional resources where possible.** GKE regional clusters, Cloud SQL regional instances, multi-zone Cloud Storage.
5. **All secrets in Secret Manager.** Nothing sensitive in manifests or environment variables.

## Phase G1 — VPC

| Resource | Purpose |
| --- | --- |
| `google_compute_network` | Custom-mode VPC |
| `google_compute_subnetwork` | Regional subnet with pods/services secondary ranges |
| `google_compute_router` + `google_compute_router_nat` | Egress for private nodes |
| `google_compute_firewall` | Internal + IAP SSH rules |

Secondary ranges (`pods`, `services`) are required for VPC-native GKE clusters — the modern default. Without them, GKE falls back to routes-based networking, which is deprecated.

Cloud NAT lets private nodes reach the internet for pulling images and calling APIs, without giving them public IPs.

## GCP vs AWS differences

| Aspect | AWS | GCP |
| --- | --- | --- |
| Network model | Public + private subnets | Single subnet, public/private via node config |
| NAT | NAT Gateway (per AZ) | Cloud NAT (regional) |
| IAM for pods | IRSA (OIDC federation) | Workload Identity |
| Kubernetes | EKS (managed control plane) | GKE (Autopilot or Standard) |
| Container registry | ECR | Artifact Registry |
| Object storage | S3 | Cloud Storage |
| Relational DB | RDS | Cloud SQL |
| Queue | SQS | Pub/Sub |
| Load balancing | ALB (via controller) | Cloud Load Balancing (via GKE Ingress) |
| Secrets | Secrets Manager | Secret Manager |
| Logs/metrics | CloudWatch | Cloud Logging / Cloud Monitoring |

These are the deltas the two repos demonstrate side by side.
