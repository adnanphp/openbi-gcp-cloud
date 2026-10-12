# Verification status

## Tiers

| Tier | Meaning |
| --- | --- |
| ✅ Syntax | Valid HCL/YAML/JSON |
| ✅ Static | Passes `terraform validate`, `tflint` |
| ⚠️ Plan | `terraform plan` runs without creating resources |
| ❌ Applied | Deployed to a real GCP project |

## Current status

| Layer | Syntax | Static | Plan | Applied |
| --- | --- | --- | --- | --- |
| Terraform — VPC module | ✅ | ✅ | ❌ | ❌ |
| Terraform — dev composition | ✅ | ✅ | ❌ | ❌ |
| Kubernetes manifests | — | — | — | — |

## Notes

- **Plan not run.** `terraform plan` requires GCP credentials and a
  project to query provider data sources. It does not create resources.
- **Not applied.** No GCP project has been used. IAM bindings, quota
  limits, region availability, and service enablement are unverified.

## What's verified locally

```bash
./scripts/validate.sh
Runs terraform fmt -check, terraform init -backend=false,
terraform validate. No GCP account required.
