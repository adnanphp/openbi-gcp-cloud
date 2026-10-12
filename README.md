# OpenBI on GCP

> GCP deployment architecture for [OpenBI](https://github.com/adnanphp/openbi) — the same data platform that runs locally, deployed against GCP managed services.

[![Validate](https://github.com/adnanphp/openbi-gcp-cloud/actions/workflows/validate.yml/badge.svg)](https://github.com/adnanphp/openbi-gcp-cloud/actions/workflows/validate.yml)

## ⚠️ Verification status

Complete GCP deployment configuration for OpenBI. **Statically validated. Not deployed to a live GCP project.**

| Layer | Status |
| --- | --- |
| Terraform syntax + schema | ✅ `terraform validate` passes |
| Terraform formatting | ✅ `terraform fmt -check` passes |
| Terraform linting | ✅ `tflint` passes |
| Kubernetes manifests | 📋 planned |
| End-to-end deployment | ❌ not verified — requires a GCP project |

See [docs/verification.md](docs/verification.md).

## The mapping

| Local (OpenBI) | GCP |
| --- | --- |
| Kind cluster | **Google Kubernetes Engine (GKE)** |
| Traefik / ALB | **Cloud Load Balancing** + GKE Ingress |
| MinIO | **Cloud Storage** |
| Redis | **Memorystore for Redis** |
| Kafka | **Pub/Sub** |
| PostgreSQL | **Cloud SQL for PostgreSQL** |
| LocalStack | **real GCP** |
| OpenFaaS | **Cloud Run / Cloud Functions** |
| Loki + Promtail | **Cloud Logging** |
| Prometheus | **Cloud Monitoring** |
| Docker images | **Artifact Registry** |
| Kubernetes Secrets | **Secret Manager** |

Companion repos:
- [openbi-aws-cloud](https://github.com/adnanphp/openbi-aws-cloud) — AWS equivalent

## Repo structure
openbi-gcp-cloud/
├── docs/
├── scripts/
│ └── validate.sh
├── terraform/
│ ├── modules/
│ │ └── vpc/ ← Phase G1
│ └── environments/
│ └── dev/
└── .github/workflows/
└── validate.yml

text

## Status

- ✅ **G1** — VPC, subnet, Cloud NAT, firewall rules
- ✅ **G2** — IAM: GKE node SA + workload identity template SA
- ✅ **G3** — Artifact Registry (Docker repository with cleanup policy)
- ✅ **G4** — GKE cluster with two node pools + Workload Identity
- ✅ **G5** — Cloud Storage (raw, processed, models buckets)
- ✅ **G6** — Cloud SQL PostgreSQL (private IP, IAM auth, backups)
- ✅ **G7** — Pub/Sub (topic + subscription + DLQ)
- 📋 G8–G11 — planned

See [ROADMAP.md](ROADMAP.md).

## Validation

```bash
./scripts/validate.sh
No GCP project required.

License
MIT
