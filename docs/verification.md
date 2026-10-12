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

---

## Current status (all phases G1–G11 complete)

| Layer | Syntax | Static | Applied |
| --- | --- | --- | --- |
| Terraform — all modules | ✅ | ✅ | ❌ |
| Terraform — dev composition | ✅ | ✅ | ❌ |
| Kubernetes manifests | ✅ | ⏳ | ❌ |
| Shell scripts | ✅ | — | ❌ |
| End-to-end deployment | — | — | ❌ |

**Legend:**
- ✅ verified
- ⏳ not yet validated in CI (kubeconform not wired)
- ❌ not verified
- — not applicable

## What's not validated

- Kubernetes manifests are syntactically correct but not validated by
  `kubeconform` in CI.
- Shell scripts have not been executed end-to-end.
- `terraform plan` has not been run (requires GCP credentials).
- The complete deployment has not been applied to a real project.

## What would change this

Running `terraform plan` (read-only) against a real GCP project would
move the Terraform rows from ⚠️ to ✅. Running `terraform apply` would
move them to "Applied." Neither is required to use this repository as
a reference.
