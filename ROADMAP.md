# OpenBI on GCP — Roadmap

Sequential phases, each ending with a commit and a green CI run.

- ✅ **G1 — VPC** (custom-mode VPC, subnet with secondary ranges, Cloud NAT, firewall rules, VPC Flow Logs)
- ✅ **G2 — IAM foundation** (GKE node SA, workload identity template SA, least-privilege roles)
- ✅ **G3 — Artifact Registry** (Docker repository with cleanup policy)
- ✅ **G4 — GKE** (Standard regional cluster, primary + spot node pools, Workload Identity, private nodes)
- ✅ **G5 — Cloud Storage** (raw / processed / models buckets, lifecycle, uniform access)
- ✅ **G6 — Cloud SQL PostgreSQL** (private IP, IAM auth, backups, tuned flags)
- ✅ **G7 — Pub/Sub** (topic + subscription + dead-letter topic)
- ✅ **G8 — Load Balancing** (static IP reservation, managed certificate examples)
- 📋 **G9 — Cloud Logging + Monitoring + Secret Manager** *(next)*
- 📋 **G10 — Kubernetes manifests** (OpenBI workloads adapted for GKE)
- 📋 **G11 — Deployment scripts + docs**
- 📋 **G12 — Optional live validation**
