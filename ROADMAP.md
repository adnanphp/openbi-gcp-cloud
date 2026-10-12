# OpenBI on GCP — Roadmap

Sequential phases, each ending with a commit and a green CI run.

- ✅ **G1 — VPC** (custom-mode VPC, subnet with secondary ranges, Cloud NAT, firewall rules, VPC Flow Logs)
- 📋 **G2 — IAM foundation** (service accounts, Workload Identity pool/provider, GKE node SA, base workload SA)
- 📋 **G3 — Artifact Registry** (Docker registry for OpenBI images)
- 📋 **G4 — GKE** (Autopilot or Standard cluster, node pools, Workload Identity enabled, add-ons)
- 📋 **G5 — Cloud Storage** (raw / processed / models buckets, lifecycle, uniform access)
- 📋 **G6 — Cloud SQL PostgreSQL** (private IP, IAM auth, backups, tuned flags)
- 📋 **G7 — Pub/Sub** (topic + subscription + dead-letter topic)
- 📋 **G8 — Load Balancing** (GKE Ingress, managed certificate)
- 📋 **G9 — Cloud Logging + Monitoring + Secret Manager**
- 📋 **G10 — Kubernetes manifests** (OpenBI workloads adapted for GKE)
- 📋 **G11 — Deployment scripts + docs**
- 📋 **G12 — Optional live validation**
